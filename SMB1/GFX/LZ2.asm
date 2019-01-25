; <copyright file="LZ2.asm" company="Public Domain">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The new LZ2 Decompression routine is designed to use
;; the MVN command to store data and execute opcodes in
;; RAM as a means of achieving much faster decompression.
;; The instruction is designed as follows:
;;
;;	RAM_Location:
;;      MVN $xxyy
;;      JMP .back
;;
;; Where 'xx' is the bank byte of the LZ2 compressed data
;; (source) and 'yy' is the bank byte of the raw GFX data
;; (destination). For more info on how MVN works, visit
;; http://ersanio.blogspot.com/2008/08/mvn-how-to.html
;;
;; I take very little credit for this. Most of the work was
;; done by some fine people at SMWC. I just rewrote it to
;; use nicer variables and make it compatable with SMAS.
;; http://www.smwcentral.net/?p=thread&id=34908
;;
;; For more information on the LZ2 decompression routine, visit
;; http://www.smwiki.net/wiki/LC_LZ2
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; These definitions all get pushed to the stack
;; so it's best to keep the one after the other
;; for efficiency's sake. Also, most of them are
;; 24-bit pointers.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!Dest_Bk_Flag = $00			;Will only have two values: 1 or -1 if the destination bank byte is $7E or $7F respectively.
!OP_MVN = !Dest_Bk_Flag+1	;RAM address which will contain the byte #$54 (opcode for MVN)
!Dest_Bk = !OP_MVN+1		;RAM address which will contain the LZ2 data bank byte (source)
!Source_Bk = !Dest_Bk+1		;RAM address which will contain the raw data bank byte (destination)
!OP_JMP = !Source_Bk+1		;RAM address which will contain the byte #$4C (opcode for JMP)
!JMP_Dest = !OP_JMP+1		;RAM address which will contain the 16-bit value address of .back in the decomression code

!LZ2_Wd_Temp = !JMP_Dest+2	;Holds the LZ2 Word value for when the X-register is needed elsewhere.

!Raw_Lo = !LZ2_Wd_Temp+2	;\
!Raw_Hi = !Raw_Lo+1			;|The 24-bit address pointer of the raw GFX data
!Raw_Bk = !Raw_Hi+1			;/
!LZ2_Lo	= !Raw_Bk+1			;\
!LZ2_Hi = !LZ2_Lo+1			;|The 24-bit address pointer of the LZ2 compressed data
!LZ2_Bk = !LZ2_Hi+1			;/
!Length = !LZ2_Bk+1			;A 16-bit value determing decompression length.

InitializeLZ2RAM:
	REP #$30
	LDY.w #EndDecompress-DecompressGFXPage
	LDX.w #$0000
-
	LDA.w DecompressGFXPage,x
	STA.l !GFX_LZ2RAM,x
	REP 2 : INX
	REP 2 : DEY
	BPL -

	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This macro will read the current byte
;; of the LZ2 data and increment the
;; location. It accounts for bank crosses
;; too. Note it's a macro and not a JSR
;; so that it saves some execution time.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ReadByte()
	STX.b !LZ2_Lo
	LDA.b [!LZ2_Lo]
	INX
	BNE ?end
	LDX #$8000
	INC.b !Source_Bk
	INC.b !LZ2_Bk
?end:
endmacro



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The LZ2 Decompression routine begins here
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DecompressGFXPage:
	PHY
	PHP
	PHB
	PEI (!Dest_Bk_Flag)		;\
	PEI (!Dest_Bk)			;|Pushes the primary addresses we will be using
	PEI (!OP_JMP)			;|onto the stack to avoid any data loss and
	PEI (!JMP_Dest+1)		;|possible crashes during gameplay.
	PEI (!LZ2_Wd_Temp+1)	;|
	PEI (!Raw_Hi)			;|
	PEI (!LZ2_Lo)			;|
	PEI (!LZ2_Bk)			;|
	PEI (!Length+1)			;/
	SEP #$20
	REP #$10
	LDA.b !Raw_Bk
	PHA
	PLB
	STA.b !Dest_Bk
	INC
	STA.b !Dest_Bk_Flag
	LDA.b #$54			;The MVN opcode byte
	STA.b !OP_MVN
	LDA.b #$4C			;The JMP opcode byte
	STA.b !OP_JMP
	LDA.b !LZ2_Bk
	STA.b !Source_Bk
	LDX.w #.back+!GFX_LZ2RAM-DecompressGFXPage		;The address of where the RAM JMP will go to.
	STX.b !JMP_Dest

	LDY.b !Raw_Lo
	LDX.b !LZ2_Lo
	STZ.b !LZ2_Lo
	STZ.b !LZ2_Hi
	BRA .main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Command 7:
;; In the event a command's length is too long,
;; this command allows a decompression routine to
;; last up to $400 bytes (rather than the standard
;; $20). It gets the new command then executes
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.case_E0
	AND.b #$03			;\
	STA.b !Length+1		;|Gets the new Length value
	EOR.b !Length		;|by reading the bits of this byte
	REP 3 : ASL A		;|and the next byte.
	XBA					;|
	%ReadByte()			;|
	STA.b !Length		;/
	XBA
	BRA .type			;The remaining bits are the command, which will be checked at .type

.case_80_or_E0
	BPL .lz
	LDA.b !Length
	CMP.b #$1F
	BNE .case_E0
	JMP .end

.lz
	%ReadByte()
	XBA
	%ReadByte()
	STX.b !LZ2_Wd_Temp
	REP #$21
	ADC.b !Raw_Lo
	TAX
	LDA.b !Length
	SEP #$20
	BIT.b !Dest_Bk_Flag
	BPL +
	MVN $7F7F
	BRA ++
+
	MVN $7E7E
++
	LDX.b !LZ2_Wd_Temp

.main
	%ReadByte()
	STA.b !Length
	STZ.b !Length+1
	AND.b #%11100000
	TRB.b !Length

.type
	ASL A
	BCS .case_80_or_E0
	BMI .case_40_or_60
	ASL A
	BMI .case_20



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Command 0:
;; Writes a direct copy of bytes
;; from the LZ2 data to raw data
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.case_00
	REP #$20
	LDA.b !Length
	STX.b !Length
-
	SEP #$20
	JMP.w !OP_MVN			;Jumps to the MVN routine in RAM

;The RAM JMP will jump to here.
.back
	CPX.b !Length
	BCS .main

	INC.b !Source_Bk
	INC.b !LZ2_Bk
	CPX #$0000
	BEQ ++

	DEX
	STX.b !LZ2_Wd_Temp
	REP #$21
	LDX #$8000
	STX.b !Length
	TYA
	SBC.b !LZ2_Wd_Temp
	TAY
	LDA.b !LZ2_Wd_Temp
	BRA -
++
	LDX #$8000
	BRA .main



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Command 1:
;; Writes a single byte repeatedly.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.case_20
	%ReadByte()
	STX.b !LZ2_Wd_Temp
	PHA				;Pushes the byte value to the stack twice
	PHA				;(for word copy instead of byte copy)
	REP #$20

.case_20_main
	LDA.b !Length	;\
	INC				;|Gets the length and halves it
	LSR A			;|because we are writing words (not bytes)
	TAX				;/

	PLA
-
	STA $0000,y		;\
	INY				;|Stores the repeated byte (or word) value to the raw data
	INY				;|address ($0000 + y-index) and repeats for half the !Length
	DEX				;|value (word coppy instead of byte).
	BNE -			;/

	SEP #$20		;\
	BCC +			;|If the Length had an odd remainder, this extra command will write
	STA $0000,y		;|the remaining byte.
	INY				;/
+
	LDX.b !LZ2_Wd_Temp
	BRA .main

.case_40_or_60
	ASL A
	BMI .case_60



;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Command 2:
;; Writes a word value (2 bytes) repeatedly
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
.case_40
	%ReadByte()		;\
	XBA				;|Reads 2 bytes. The objective is to store it as a word value
	%ReadByte()		;|which will late be PHA'd and then stored to the raw data.
	XBA				;/
	STX.b !LZ2_Wd_Temp
	REP #$20
	PHA
	BRA .case_20_main



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Command 3:
;; Writes an increasing byte fill.
;; e.g. $37, $38, $39, $3A, ...
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.case_60
	%ReadByte()
	STX.b !LZ2_Wd_Temp
	LDX.b !Length
-
	STA $0000,y
	INC A
	INY
	DEX
	BPL -
	LDX.b !LZ2_Wd_Temp
	JMP .main

.end
	PLX : STX.b !Length+1		;\
	PLX : STX.b !LZ2_Bk			;|Returns all stack values to their
	PLX : STX.b !LZ2_Lo			;|respective addresses.
	PLX : STX.b !Raw_Hi			;|
	PLX : STX.b !LZ2_Wd_Temp	;|
	PLX : STX.b !JMP_Dest+1		;|
	PLX : STX.b !OP_JMP			;|
	PLX : STX.b !Dest_Bk		;|
	PLX : STX.b !Dest_Bk_Flag	;/
	REP #$20
	TYA
	SEC
	SBC.b !Raw_Lo
	STA.b !Length
	PLB
	PLP
	PLY
	RTL
EndDecompress:
