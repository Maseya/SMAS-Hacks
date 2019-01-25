; <copyright file="GFX.asm" company="Public Domain">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file installs a very complex custom GFX routine
;; to SMAS SMB1. Ths file aims at accomplishing several
;; goals:
;;
;; 1) Custom GFX per level
;;	SMAS SMB1 uses a system to insert GFX which is designed
;;	to save space. This proves inefficient to the modern hacker,
;;	so of course, making a better GFX loading system is a must.
;;
;; 2) Allowing up to 0x1000 GFX files
;;	If GFX per level routine is to be created, it is obvious that
;;	there should be more GFX to choose from. Following Lunar Magic's
;;	design, the limit will be set at 0x1000 which is more than reasonable.
;;
;; 3) LZ2 Compression
;;	Having 0x1000 GFX files exist uncompressed is a very bad idea!
;;	LZ2 Compression is a popular algorithm used by SMW, Yoshi's Island,
;;	Zelda III, and other great SNES games. SMAS does not use this, so
;;	it would be smart to implement it.
;;
;; 4) Fix several problems caused by (1) through (3)
;;	Many issues have arisen due to installing all the previous ASM hacks.
;;	Most notable are any cutscene GFX (game over, time up, prelevel scene,
;;	save princess peach scene, etc.) So we need to fix all of that.
;;
;; That is indeed a lot to cover and the length and true complexual
;; nature of the GFX.asm file (and it's sibling branches) will show
;; that.
;;
;; You can modify this, but be careful. A lot of what goes on in this
;; file is deeply integrated to other parts of the game.
;;
;; Code �2009-2010 spel werdz rite (SWR)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Definitions of stuff
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!AnimGFX1 = $7F4000		;\
!AnimGFX2 = $7F5000		;|RAM address locations of where
!AnimGFX3 = $7F6000		;|the animated GFX will be stored.
!AnimGFX4 = $7F7000		;/

!MainGFX = $7F8000		;This serves as a GFX "template" when doing VRAM transfers

!PlayerGFX1 = $7F8000	;Page 1 of the current player's GFX
!PlayerGFX2 = $7F9000	;Page 2 of the current player's GFX

!MiscGFX = $7FA000		;Holds some extra GFX data for random cutscenes
!PrincessGFX = $7FB000	;GFX data of the "Rescue Princess" cutscene



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This clears some old data and makes a
;; few modications to certain bytes, as
;; well as jump to new routines when needed.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;GFX Initialization Routine
ORG $03812B
	REP $59 : NOP
ORG $03812B
	JSL InitGFX

ORG $049266
	JSL LoadCutsceneGFX

ORG $049313
	JSL LoadPreviewLevelGFX

ORG $049655
	REP $03 : NOP

;Changes which address to load the Player GFX from.
ORG $04D834
	dw !PlayerGFX1
ORG $04D847
	REP $0D : NOP
	LDA #$7F

ORG $04DD87
	db $7F
ORG $04DD9C
	db $B0

ORG $04ED2E
	REP $2C : NOP
ORG $04ED2E
	RTL

;Changes addresses of animation frame GFX files.
ORG $05E64C
	db $7F
ORG $05E654
	db $00
ORG $05E687
	db $7F
ORG $05E699
	db $AB

ORG $05E6AF
	REP $01CA : NOP
ORG $05E6B1
	JML LoadLevelGFX



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; These are some fundamental data files
;; which insert the LZ2 data and get their pointers.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
incsrc SMB1\GFX\Files.asm
incsrc SMB1\GFX\Tables.asm
incsrc SMB1\GFX\Files_Locs.asm
incsrc SMB1\GFX\Files_Ptrs.asm



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is the actual start of the GFX ASM hack.
;; It's a pretty big mess, but I've tried my best
;; to keep it legible.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG !GFX_ASM
	incsrc SMB1\GFX\LZ2.asm
DoDecompress:
	LDA.l GFX_Lo,x
	STA.b !LZ2_Lo
	LDA.l GFX_Hi,x
	STA.b !LZ2_Hi
	LDA.l GFX_Bk,x
	STA.b !LZ2_Bk
	JSL !GFX_LZ2RAM
	RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is a GFX Initialization routine. At the
;; start of a game, the standard GFX files are
;; loaded into the respective spots. This is
;; sort of the "fallback" template for all GFX.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	incsrc SMB1/GFX/Static.asm
InitGFX:
	PHB
	PHP
	PHK
	PLB

	JSR.w InitializeLZ2RAM

	REP #$10
	SEP #$20


	LDA.b #$80				;\
	STA.w $2115				;|This mostly just sets up some pre-DMA
	LDA.b #$7F				;|trasnfer stuff, like disabling interrupts
	STA.w $4304				;|and selecting transfer locations.
	STA.b !Raw_Bk			;|
	LDX.w #$1801			;|
	STX.w $4300				;|
	LDX.w #!MainGFX			;|
	STX.b !Raw_Lo			;/

	LDX.w #!MiscGFX			;\
	STX.b !Raw_Lo			;|!MiscGFX is a RAM location with a GFX file designed to never
	LDX.w #$0026			;|change (unless you want it to). The purpose of this DMA transer
	JSR DoDecompress		;|is to take the 2BPP GFX from GFX file $26 and permanently save it.
	LDX.w #$5000			;|It's used mostly in the status bar, but also for the water animation
	STX.w $2116				;|in underwater levels.
	LDX.w #!MiscGFX+$800	;|Because it's only $800 bytes, I'm considering making this a raw GFX
	STX.w $4302				;|ROM location to free up some RAM. You free to modify this and do so
	LDX.w #$0800			;|yourself. Please don't ask me how though. Like I said before, modifcation
	STX.w $4305				;|is for experience users only.
	LDA.b #$01				;|
	STA.w $420B				;/

	LDY.w #$0006
-
	LDX.w AnimGFX_Table1,y	;\
	STX.b !Raw_Lo			;|This routine is very straightforward: Load the animated GFX RAM location,
	LDX.w AnimGFX_Table2,y	;|then the GFX file to store there, then just decompress it. Note that we're
	JSR DoDecompress		;|not doing a DMA transfer. Just writing the animated GFX to the desired RAM location.
	REP 2 : DEY				;|The game takes care of the actual anmation when the event occurs.
	BPL -					;/

	LDX.w #!PrincessGFX		;\
	STX.b !Raw_Lo			;|This is also straightforward: Take GFX file $000E (saved princess cutscene GFX) and
	LDX.w #$000E			;|save it to #!PrincessGFX. The game will load it when the even occurs.
	JSR DoDecompress		;/

	PLP
	PLB
	RTL



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This routine aims at inserting custom GFX
;; into the DMA when they are needed. The only
;; two cutscenes I've noticed are needed are
;; Game Over and Time Up screens.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadCutsceneGFX:
	PHP
	PHB
	PHK
	PLB
	REP #$10
	SEP #$20

	LDA.b #$80				;\
	STA.w $2115				;|Sets up a DMA transfer for the cutscene.
	LDA.b #$7F				;|If you are unsure why !MainGFX is always used,
	STA.w $4304				;|it's because it's not a static RAM table. It's use
	STA.w !Raw_Bk			;|is to have a GFX page exist for a DMA transfer, so it
	LDX.w #$1801			;|can be used pretty much at any time. The othr RAM tables
	STX.w $4300				;|however are supposed to be static (you can change them
	LDX.w #!MainGFX			;|if you have a way which suites what you need done).
	STX.b !Raw_Lo			;|
	STX.w $4302				;/

	LDX.w #$0011			;GFX011 is the Game Over/Time Up GFX
	JSR DoDecompress
	LDX.w #$3400
	STX.w $2116
	LDX.w #$1000
	STX.w $4305
	LDA.b #$01
	STA.w $420B

	LDX.w #!MainGFX+$800
	STX.w $4302
	LDX.w #$001B			;GFX01B also has Game Over/Time Up GFX
	JSR DoDecompress
	LDX.w #$2C00
	STX.w $2116
	LDX.w #$0800
	STX.w $4305
	LDA.b #$01
	STA.w $420B

	PLB
	PLP
	RTL



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is the grand daddy of the custom GFX loading.
;; This routine is the core of getting all GFX from pointers
;; and loading them to their respective levels. So as
;; you will guess, it's pretty long and probably a little
;; complex. But it shouldn't be too bad to get through
;; most of it.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadLevelGFX:
	PHP
	PHB
	PHK
	PLB
	REP #$10
	SEP #$20
	PEI (!Dest_Bk_Flag)		;\
	PEI (!Dest_Bk)			;|Pushes the primary addresses we will be using
	PEI (!OP_JMP)			;|onto the stack to avoid any data loss and
	PEI (!JMP_Dest+1)		;|possible crashes during gameplay.
	PEI (!LZ2_Wd_Temp+1)	;|
	PEI (!Raw_Hi)			;|
	PEI (!LZ2_Lo)			;|
	PEI (!LZ2_Bk)			;|
	PEI (!Length+1)			;/

	LDA.w $0750
	AND.b #$7F
	STA.b !Raw_Lo
	LDA.w $07FC
	AND.b #$02
	BEQ +
	LDA.b #$80
	CLC
	ADC.b !Raw_Lo
	STA.b !Raw_Lo
+
	LDA.b !Raw_Lo
	JSR.w InsertLevelGFX

	LDY.w #$0002
-
	LDX.w PlayerGFX_Table1,y	;The objective of this loop is to determine which player
	STX.b !Raw_Lo				;is selected, obtain the GFX for said player, then store it
	LDX.w PlayerGFX_Table2,y	;!PlayerGFX1 and !PlayerGFX2. Note that the two values don't
	LDA.w $0EC2					;mean GFX for Player 1 and Player 2 repectively. The player GFX
	AND.b #$FF					;take two pages. So the addresses represent the first and second
	BEQ  +						;page respectively. Thus, it is necessarry to call this at level
	LDX.w PlayerGFX_Table2+4,y	;load and not during the Initialization routine.
+								;This is another event when I feel I should have raw GFX and just
	CPX.w #$FFFF				;handle it during the init routine. It would free up more RAM and
	BEQ +						;save on loading time.
	JSR DoDecompress
+
	DEY
	DEY
	BPL -

	PLX : STX.b !Length+1		;\
	PLX : STX.b !LZ2_Bk			;|Returns all stack values to their
	PLX : STX.b !LZ2_Lo			;|respective addresses.
	PLX : STX.b !Raw_Hi			;|
	PLX : STX.b !LZ2_Wd_Temp	;|
	PLX : STX.b !JMP_Dest+1		;|
	PLX : STX.b !OP_JMP			;|
	PLX : STX.b !Dest_Bk		;|
	PLX : STX.b !Dest_Bk_Flag	;/
	PLB
	PLP
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Some level preview screen (ex. W1-2) load
;; the GFX of the next level, rather than the
;; current one. This routine accounts for that.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadPreviewLevelGFX:
	PHB
	PHK
	PLB
	PHP
	REP #$30
	PEI (!Dest_Bk_Flag)		;\
	PEI (!Dest_Bk)			;|Pushes the primary addresses we will be using
	PEI (!OP_JMP)			;|onto the stack to avoid any data loss and
	PEI (!JMP_Dest+1)		;|possible crashes during gameplay.
	PEI (!LZ2_Wd_Temp+1)	;|
	PEI (!Raw_Hi)			;|
	PEI (!LZ2_Lo)			;|
	PEI (!LZ2_Bk)			;|
	PEI (!Length+1)			;/
	PHP

	JSL.l LoadPreviewLevel
	JSR.w InsertLevelGFX

	PLP
	PLX : STX.b !Length+1		;\
	PLX : STX.b !LZ2_Bk			;|Returns all stack values to their
	PLX : STX.b !LZ2_Lo			;|respective addresses.
	PLX : STX.b !Raw_Hi			;|
	PLX : STX.b !LZ2_Wd_Temp	;|
	PLX : STX.b !JMP_Dest+1		;|
	PLX : STX.b !OP_JMP			;|
	PLX : STX.b !Dest_Bk		;|
	PLX : STX.b !Dest_Bk_Flag	;/
	PLP
	PLB
	RTL



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The event of inserting the level GFX
;; occurs twice. Once during the actual
;; level load, but a time before that during
;; the level preview screen. For certain
;; reasons, the two routines are not exact,
;; but that doesn't mean that this part of
;; the routine can't be.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InsertLevelGFX:
	PHP
	PEI ($00)
	REP #$30
	AND.w #$00FF
	STA.b $00

	SEP #$20
	LDX.w #!MainGFX			;\
	STX.b !Raw_Lo			;|Sets up !MainGFX for several DMA Transfers.
	LDA.b #$7F				;|The objective of the following loop is to load
	STA.b !Raw_Bk			;|the level pointer, determine the GFX file, decompress
	STA.w $4304				;|that GFX page, and do a DMA transfer to it's respective
	LDA.b #$80				;|location. Then repeat for all level GFX (objects and sprites).
	STA.w $2115				;|This was not an easy algorithm to set up and I'm sure
	LDX.w #$1801			;|it could use some work.
	STX.w $4300				;/

	LDY.w #$000E
-
	REP #$30				;We keep the REP in the loop because the status register will change.
	TYA						;\
	REP 7 : ASL A			;|The pointer is now a multiple of $100 bytes (for each loop index).
	STA.b !LZ2_Lo			;/
	LDA.b $00				;\
	CLC						;|We're not done yet though, there are other factors at play.
	ADC.b !LZ2_Lo			;/
	ASL A					;We double the index because it's relative to words, not bytes.
	TAX
	LDA.l GFX_Table1,x		;\
	CMP.w #$FFFF			;|A lot is going on here, so it may be a tad confusing. First, we check
	BEQ +					;|GFX_Tabale1 indexed by the conditions we made earlier. If the value is
	AND.w #$0FFF			;|$FFFF, that means no value has been selected so we go to the default (which
	TAX						;|is selected from GFX_Table3, which matches InitGFXTable1, but with switched
	BRA ++					;|values to match the indexes). If it isn't $FFFF, then our value is the GFX
+							;|index, then we move on to decompress it.
	LDX GFX_Table3,y		;/
++
	SEP #$20				;This is why we keep the REP #$30 in the loop at the beginning.
	JSR DoDecompress		;\
	LDX.w GFX_Table2,y		;|We now have the GFX page decompressed to !MainGFX. So we look up
	STX.w $2116				;|GFX_Table2 to determine which VRAM address we will store it to.
	LDX.w #!MainGFX			;|The rest is just a standard DMA transfer.
	STX.w $4302				;|
	LDX.w #$1000			;|
	STX.w $4305				;|
	LDA.b #$01				;|
	STA.w $420B				;/
	REP 2 : DEY
	BPL -

	REP #$30
	LDA.b $00
	ASL A
	TAX
	LDA.l ObjGFX_Table3,x
	CMP.w #$FFFF
	BEQ +
	PHA
	AND.w #$0FFF
	TAX
	PLA
	AND.w #$1000
	STA.w $02F8
	BEQ ++
	LDA.w $0EC2
	AND.w #$00FF
	BEQ ++
	INX
	BRA ++
+
	LDX.w #$0002
++
	SEP #$20
	JSR DoDecompress
	LDX.w #$2000
	STX.w $2116
	LDX.w #!MainGFX
	STX.w $4302
	LDX.w #$1000
	STX.w $4305
	LDA.b #$01
	STA.w $420B

	REP #$30
	PLA
	STA $00
	PLP
	RTS
