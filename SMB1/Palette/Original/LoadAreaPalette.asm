; <copyright file="LoadAreaPalette.asm" company="Maseya">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;; byte: Area index of current player
!AreaIndex = $7E00DB

;; byte: Determines whether current area is an auto-walk area.
!SavedAreaIndex = $7E0E65

;; const byte: Area index of W2-2 and W7-2 underwater area.
!UnderWaterLevelAreaIndex = #$01;

;; const byte: Area index of W1-2, W2-2, W4-2 and W7-2 auto-walk area.
!AutoWalkAreaIndex = #$0C

;; const byte: Area index of W1-2 and W4-2 underground area.
!UnderGroundLevelAreaIndex = #$19

;; byte: World number (starting at 0) of current player.
!CurrentWorld = $7E075F

;; byte[0x200]: Stores palette data that OAM will read from on redraw.
!PaletteOAMMirror = $7E1000

;; bool8: Indicates whether the current area is a bonus area.
!IsBonusArea = $7E02F8

;; bool8: Indicates whether Luigi is the current player.
!IsLuigiPlaying = $7E0753

;; byte[0x220]: Specifies which row of colors to read from PaletteData.
!PaletteRowIndexTable = $0497CD

;; word[0x42]: Specifies the start index of PaletteData for a given row index.
!PaletteIndexTable = $04AE3F

;; word[0x03E0]: SMB1 color data. Data is read by 0x10 word rows.
!PaletteData = $04AEC3

ORG $0495E2
;; *
;; LoadAreaPalette()
;;
;; Summary:
;;      Load the current area's initial palette.
;;
;; Reads from:
;;      SavedAreaIndex - To possibly set AreaIndex.
;;      AreaIndex - To possibly set SavedAreaIndex and to get palette data.
;;      CurrentWorld - To determine if SavedAreaIndex should be set.
;;      IsBonusArea, IsLuigiPlaying - To determine whether some palette colors
;;          should be changed for Luigi's bonus areas.
;;      PaletteRowIndexTable - To determine which row from PaletteData to read
;;          from while writing to a row of PaletteOAMMirror
;;      PaletteIndexTable - To determine the offset in PaletteData a row index
;;          starts at.
;;      PaletteData - To get the initial Palette data for the current area.
;;
;; Writes to:
;;      AreaIndex - If SavedAreaIndex was set.
;;      SavedAreaIndex - If AreaIndex needs to change for preview level screens.
;;      PaletteOAMMirror - Set the initial area's Palette data.
;;
;; Temporary variables:
;;      $7E:0002.w
;;      $7E:0004.w
;;      $7E:0006.w
;;
;; Remarks:
;;      This function is called twice. Once when when a new level starts and the
;;          preview screen is shown (the screen before the level starts that
;;          shows the main area type and enemies), and again every time the
;;          player enters an area in this level.
;;
;;      There is special logic to handle when the player is starting at W1-2,
;;          W2-2, W4-2, or W7-2. These are undergound and underwater levels.
;;          The level preview screen needs to show the correct area type which
;;          is different from the level's start area (the auto-walk sequence
;;          into the pipe).
;;
;;      During the level start call, the function checks whether the initial
;;          value of AreaIndex is an auto walk area. If it is, AreaIndex will be
;;          set to UnderGroundLevelAreaIndex or UnderWaterLevelAreaIndex,
;;          depending on the current WorldNumber value.
;;
;;      On the following call, the function checks whether we changed AreaIndex
;;          as mentioned above, and then restores it to it's original value.
;;
;;      The palette colors loaded depend on the current AreaIndex. A selection
;;          of palette rows is chosen by a lookup table indexed by AreaIndex.
;;
;;      The function also checks whether we are currently in a bonus area and
;;          whether Luigi is the current player. In which case, the bonus area
;;          palette is updated to use Luigi's colors instead of Mario's.
;; *
LoadAreaPalette:
{
    ; if SavedAreaIndex != 0:
    LDA.w !SavedAreaIndex
    BEQ   .update_preview_level
    {
        ; AreaIndex = SavedAreaIndex
        STA.b !AreaIndex

        ; SavedAreaIndex = 0
        STZ.w !SavedAreaIndex
        BRA   .begin_read
    }
.update_preview_level
    ; else if AreaIndex == AutoWalkAreaIndex
    LDA.b !AreaIndex
    CMP.b !AutoWalkAreaIndex
    BNE   .begin_read
    {
        ; SavedAreaIndex = AreaIndex
        STA.w !SavedAreaIndex

        ; if CurrentWorld != 0 && CurrentWorld != 3
        LDA.w !CurrentWorld
        BEQ   +
        CMP.b #$03
        BEQ   +
        {
            ; AreaIndex = UnderWaterLevelAreaIndex
            LDA.b !UnderWaterLevelAreaIndex
            STA.b !AreaIndex
            BRA   .begin_read
        }
    +   ; else
        {
            ; AreaIndex = UnderGroundLevelAreaIndex
            LDA.b !UnderGroundLevelAreaIndex
            STA.b !AreaIndex
        }
    }

.begin_read
    REP   #$30

    ; SrcIndex = AreaIndex << 4
    !SrcIndex = $7E006
    LDA.b !AreaIndex
    AND.w #$00FF
    ASL   A
    ASL   A
    ASL   A
    ASL   A
    TAY
    STY.b !SrcIndex

    ; for DestIndex = 0
    !DestIndex = $7E0002
    STZ.b !DestIndex
-
    ; do
    {
        ; A = PaletteRowIndexTable[SrcIndex] & 0x00FF
        LDY.b !SrcIndex
        LDA.w !PaletteRowIndexTable,y
        AND.w #$00FF
        INY
        STY.b !SrcIndex

        ; Y = PaletteIndexTable[A << 1]
        ASL   A
        TAX
        LDA.w !PaletteIndexTable,x
        TAY

        ; for X = DestIndex, Counter = 0x0007
        LDX.b !DestIndex
        !Counter = $7E0004
        LDA.w #$0007
        STA.b !Counter
    --
        ; do
        {
            ; PaletteOAMMirror[X] = PaletteData[Y]
            ; PaletteOAMMirror[X + 0x10] = PaletteData[Y + 0x10]
            LDA.w !PaletteData,y
            STA.w !PaletteOAMMirror,x
            LDA.w !PaletteData+$10,y
            STA.w !PaletteOAMMirror+$10,x

            ; X += 2, Y += 2
            INX
            INX
            INY
            INY
        }
        ; while --Counter >= 0
        DEC.b !Counter
        BPL   --

        ; DestIndex = X + 0x10
        TXA
        CLC
        ADC.w #$0010
        STA.b !DestIndex
    }
    ; while DestIndex != 0x01E0
    CMP.w #$01E0
    BNE   -

    ; if IsBonusArea && IsLuigiPlaying
    LDA.w !IsBonusArea
    AND.w #$00FF
    BEQ   .end
    LDA.w !IsLuigiPlaying
    AND.w #$00FF
    BEQ   .end
    {
        ; for Y = 0x0000, X = 0x00E0
        LDY.w #$0000
        LDX.w #$00E0
    -
        ; do
        {
            ; PaletteOAMMirror[X++] = LuigiBonusAreaPalette[Y++]
            LDA.w .LuigiBonusAreaPalette,y
            STA.w !PaletteOAMMirror,x
            INX
            INX
            INY
            INY
        }
        ; while Y != 0x0020
        CPY.w #$0020
        BNE   -

        BRA   .end

    .LuigiBonusAreaPalette
        incbin "SMB1\Palette\Original\LuigiBonusArea.rpf"
    }
.end
}

ORG !PaletteRowIndexTable
incbin "SMB1\Palette\Original\PaletteRowIndexTable.bin"

ORG !PaletteIndexTable
incbin "SMB1\Palette\Original\PaletteIndexTable.bin"

ORG !PaletteData
incbin "SMB1\Palette\Original\PaletteData.rpf"
