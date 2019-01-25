; <copyright file="Maps.asm" company="Public Domain">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The custom map ASM was actually my first SMAS
;; redesign back in 2006. The idea was to allow
;; levels to be loaded with full 24-bit address
;; support. I quickly learned to add some more useful
;; aesthetics like allowing any map type to any level,
;; custom time and start positions, and, best of all,
;; support for 256 levels! (128 for normal and hard quest)
;;
;; The ASM has undergone countless rewrites. This is
;; it's current state. It's written at SNES $04C000,
;; the location of the original map loading routine.
;; There are $1800 free bytes here, which is plenty
;; of space for all the ASM and pointers.
;;
;; Code �2009-2012 spel werdz rite (SWR)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Definitions of stuff
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!InfiniteTime = $0710	;If set, the level has no time limit
!LoadNextLevel = $074F	;Flag used for showing the next level's data for the preview screen

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The two main functions get called quite a few
;; times. Because I changed their locations, I need
;; to change the JSL jumps too.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $0387EC
	JSL.l WriteMaps
ORG $038AFB
	JSL.l WriteMaps
ORG $039E01
	JSL.l WriteMaps
ORG $039E13
	JSL.l WriteMaps
ORG $039E7C
	JSL.l WriteMapData
ORG $03A204
	JSL.l WriteMaps
ORG $03B368
	JSL.l WriteMaps

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Removes the original routine for loading the
;; player's start position. This is overwritten.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $039FF1
	REP 12 : NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Clears all old Map insertion data.
;; It is now quite useless to us.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $04C000
	fillbyte $FF : fill $1800
	incsrc SMB1\Maps\Static.asm
	incsrc SMB1\Maps\Files_Locs.asm
	incsrc SMB1\Maps\Files_Ptrs.asm
	incsrc SMB1\Maps\Enemy\Files_Locs.asm
	incsrc SMB1\Maps\Enemy\Files_Ptrs.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; WriteMaps ASM sets up which map
;; number we want based on the level and
;; world we are currently at. Other
;; factors come into play too.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteMaps:
	PHB
	PHK
	PLB
	LDY.w $07FC				;\
	LDA.w $075F				;|Checks if the current world has exceeded the max world for the specified quest number.
	CMP.w MaxWorlds+1,y		;/
	BCC +
	STZ.w $0760				;\
	STZ.w $075C				;|Reset the world and level values to 1-1 once we've "completed" the quest.
	STZ.w $075F				;/
+
	TYA						;\
	REP 3 : ROR A			;|Checks if this is the new quest (values 2 or 3) and sets a flag of $80 to $0750
	AND.b #$80				;|This is an additive index for loading levels later.
	STA.w $0750				;/
	LDA.w MaxWorlds,y		;\
	CLC						;|This adds the number of worlds "completed" per quest and adds to the current world
	ADC.w $075F				;|to use as an index for determining the number of levels "completed" so far.
	TAY						;/
	LDA.w MaxLevels,y		;\
	CLC						;|We get the number of levels completed up to this world and add the level number we are
	ADC.w $0760				;|currently on to get a unique level number. We then add the value of $0750 which stored
	CLC						;|an additive flag. The result is a unique index per level per quest number which we use
	ADC.w $0750				;| to determine which map to load.
	TAY						;/
	LDA.w Maps,y			;Load map value from table indexed by current level and quest number.
	STA.w $0750				;This was used as a dummy address earlier, but now permanently holds the map number.
	PLB
	RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; WriteMapData ASM takes the map number
;; we got in WriteMaps ASM and uses it to
;; get the data pointers for the level.
;; We also get all data from the header.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteMapData:
	PHB
	PHK
	PLB
	LDA.w $07FC		;\
	REP 3 : ROR A	;|The quest value will give us an additive flag of $80 with a value of 2 or 3.
	AND.b #$80		;|We use this index for determining the appropriate map pointers.
	STA.w $074F		;/
	LDA.w $0750		;\
	AND.b #$7F		;|The map number can have the last bit set if we are loading a map from a pipe entrance.
	ORA.w $074F		;|We combine with quest flag to get a unique index for determining pointers for the map.
	TAY				;/
	LDA.w MapLo,y
	STA.b $FA
	LDA.w MapHi,y
	STA.b $FB
	LDA.w MapBk,y
	STA.b $FC
	LDA.w EnemyLo,y
	STA.b $FD
	LDA.w EnemyHi,y
	STA.b $FE
	LDA.w EnemyBk,y
	STA.b $FF
	LDY.b #$00
	LDA.b [$FA],y
	AND.b #%11000000
	CLC
	REP 3 : ROL A
	STA.b $5C
	STA.b $BA
	LDA.b [$FA],y
	AND.b #%00100000
	STA.w !LoadNextLevel
	LDA.b [$FA],y
	AND.b #$0F
	STA.w $07E9
	STA.w !InfiniteTime
	BNE +
	INY
	LDA.b [$FA],y
	STA.w !InfiniteTime
	BEQ ++
	DEY
+
	INY
	LDA.b [$FA],y
	REP 4 : LSR A
	STA.w $07EA
	LDA.b [$FA],y
	AND.b #$0F
	INC A
	STA.w $07EB
++
	INY
	LDA.b [$FA],y
	STA.w $219
	INY
	LDA.b [$FA],y
	STA.w $237
	INY
	LDA.b [$FA],y
	STA.b $DB
	LDA.b $FA
	CLC
	ADC.b #$05
	STA.b $FA
	LDA.b $FB
	ADC.b #$00
	STA.b $FB
	STZ.w $0EE8
	PLB
	RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This little hack is used to get the preview
;; level map number. This used for getting the
;; GFX and Palette that will use it.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadPreviewLevel:
	PHB
	PHK
	PLB
	PHP
	SEP #$30
	LDX.w $07FC
	LDA.w MaxWorlds,x
	CLC
	ADC.w $075F
	TAX
	LDA.w MaxLevels,x
	CLC
	ADC.w $0760
	STA.b $00
	LDA.w !LoadNextLevel
	BEQ +
	LDA.b $00
	INC A
	BRA ++
+
	LDA.b $00
++
	TAX
	LDA.w Maps,x
	AND.b #$7F
	STA.b $00
	LDA.w $07FC
	AND.b #$02
	BEQ +
	LDA.b #$80
	CLC
	ADC.b $00
	STA.b $00
+
	LDA.b $00
	PLP
	PLB
	RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; We include the physical level data
;; to the ROM.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
incsrc SMB1\Maps\Files.asm
incsrc SMB1\Maps\Enemy\Files.asm
