; <copyright file="Palette.asm" company="Public Domain">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The Custom Palette ASM was executed with quick success
;; All code was actually made well enough to fit in the original
;; address location. Note that this means it doesn't jump anywhere,
;; so if you want to expand it, you should beforehand.
;;
;; The goal of this file was to simply allow for a custom
;; palette for each level. And that was done. Advanced users
;; are free to modify this file.
;;
;; Code �2009-2010 spel werdz rite (SWR)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Definitions of stuff
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!Pointer_Lo = $00			;\
!Pointer_Hi = !Pointer_Lo+1	;|24-bit address of the Palette data.
!Pointer_Bk = !Pointer_Hi+1	;/



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Files.asm basically contains all the palettes.
;; It's recommended you leave it alone. And by recommended,
;; I mean MushROMs won't work if you mess with it.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
incsrc SMB1\Palette\Files.asm
!Palette_Bk = !Palette_Files>>$10


ORG $049488
	JSR.w LoadPreviewLevelPalette
ORG $0495DD
	JSR.w LoadLevelPalette



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The Custom Palette ASM routine. If you're
;; going to modify this, it is strongly recommended
;; that you jump to a new location, as this code doesn't.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $0495E2
	REP $6F : NOP
ORG $0495E2
LoadLevelPalette:
	LDA.w $0750
	AND.b #$7F
	STA.b $00
	LDA.w $07FC
	AND.b #$02
	CLC
	REP 3 : ROR A
	ADC.b $00
	BRA PaletteASM

LoadPreviewLevelPalette:
	JSL.l LoadPreviewLevel

PaletteASM:
	STZ.b !Pointer_Lo
	PHA
	AND.b #$80
	CLC
	REP 3 : ROL A
	ADC.b #!Palette_Bk
	STA.b !Pointer_Bk
	PLA
	PHA
	AND.b #$40
	BEQ +
	INC.b !Pointer_Bk
+
	PLA						;\
	AND.b #$3F				;|Setting up the high byte also has two factors. First,
	ASL A					;|it's double the level number ($00-$3F). Then, because
	ORA.b #$80				;|this is a LOROM game, it must be at at least $8000.
	STA.b !Pointer_Hi		;/

	REP #$30
	LDY.w #$0000
-
	LDA.b [!Pointer_Lo],y	;\
	STA.w $1000,y			;|This last part is also straightforward. We just set up a loop and copy
	REP 2 : INY				;|the bytes to $1000. That address will be transferred to CGRAM later on.
	CPY.w #$0200			;/
	BNE -
	;End code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Writes the new player palettes to the designated
;; spot. Note that you can't make custom player
;; palettes. I may change this one day, but for now,
;; it remains unchanged.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $0499FD
	incbin SMB1\Palette\Default\Player.rpf
