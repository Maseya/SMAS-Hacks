;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is the crowned jewel of my labor. Even more so than
;; the GFX hack. As nice as it is, this hack surpasses the complexity,
;; beauty, and utility of the GFX hack. The goal of this file
;; is to mainly throw out the entire level loading system SMB1
;; used to use. It was very narrow and didn't allow for much.
;; Certainly leaving it would have lead to a very limited editor.
;; Simply fixing the limitations was not an option either, as 
;; they were too hardcoded into the routines and would be
;; ridiculous to even want to do. Therefore, my only option was
;; a total and complete rewrite (what you see before you). While
;; some of my work may not be "perfect," it certainly surpasses the
;; old method in every way (except size) and adds so much more to
;; the game. Of these, are more flexibility in adding objects,
;; rectanglular expansion rather than just horizontal or vertical,
;; and my personal favorites: direct map16 and "acts like" settings.
;; I've expanded the Map16 data from 1 page (a very limited page too)
;; to 16. The "acts like" hack is also very nice, as most map16 tile
;; properties were vines for some reason. Regardless, the work was
;; arduous but the result is beautiful!
;;
;; Code �2009-2010 spel werdz rite (SWR)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Definitions of stuff
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!objW = $00			;The object's width
!objH = $02			;The object's height
!Scratch1 = $04		;Scratch RAM
!Scratch2 = $06		;Scratch RAM

!TileAddr = $7FFFE0	;The start location to write Tiles.
!MapHeight = $0C	;The height of the level map (constant).
!lvlX = $010B		;The level's current x-position (includes pages)
!ScreenP = $0725	;Original RAM (screen page)
!ScreenX = $0726	;Original RAM (screen x-loc)
!Index = $072C		;Index of level data
!objX = $1300		;The object's starting x-position (includes pages)

ORG $03E54F
	REP 3 : NOP
ORG $03A43B
	JSR.w LevelASM
ORG $03A592
	JSR.w LevelASM
ORG $03A598
	JSR.w CODE03ACF6
ORG $03EB9C
	JSR.w CODE03ACF6

;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Initialize level
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $03A5CC
fillbyte $FF : fill $794
ORG $03A5CC
	incsrc SMB1\Levels\Static.asm
LevelASM:
	PHP                     ;Save processor status before routine
	REP #$30                ;16-bit AXY
	LDX.w #!MapHeight<<1    ;Set word index of !MapHeight to X register
-                           ;\
	LDA.w #$0000            ; |Store zero to !TileAddr for entire map height
	STA.l !TileAddr,x       ; |
	REP 2 : DEX             ; |
	BPL -                   ;/
	STZ.w !objX             ;Initialize !objX to zero
	STZ.w !Index            ;Ininitialize !Index to zero
	LDA.w !ScreenX          
	AND.w #$000F
	STA.w !lvlX
	LDA.w !ScreenP
	AND #$00FF
	REP 4 : ASL A
	ORA.w !lvlX
	STA.w !lvlX
LoadObject:
	REP #$30
	LDA.w !objX
	AND.w #$FFF0
	STA.w !objX
	LDY.w !Index
	LDA.b [$FA],y
	AND.w #$00FF
	CMP.w #$00FF
	BEQ	.end
	STA.b !Scratch1
	REP 2 : INC.w !Index
	INY
	LDA.b [$FA],y
	AND.w #$0080
	BEQ +
	LDA.w !objX
	CLC
	ADC.w #$0010
	STA.w !objX
+
	LDA.b !Scratch1
	AND.w #$000F
	CMP.w #$000F
	BNE +
	JSL.l LevelCommands
	BRA LoadObject
+
	ASL A
	TAX
	LDA.b !Scratch1
	REP 4 : LSR A
	AND.w #$000F
	ORA.w !objX
	STA.w !objX
	CPX.w #!MapHeight+1<<1
	BCS .special
	BRA .object

.end
	LDY.w #!MapHeight
	LDX.w #!MapHeight<<1
	STX.b !Scratch1
-
	LDX.b !Scratch1
	LDA.l !TileAddr,x
--
	STA.b !Scratch2
	ASL A
	TAX
	LDA.l ExMap16Set,x
	CMP.w #$00FF
	BPL --
	CMP.b !Scratch2
	BNE --
	SEP #$20
	STA.w $06A1,y
	REP	#$20
	DEY
	REP 2 : DEC.b !Scratch1
	BPL -
	PLP
	RTS

.object
	LDA.b [$FA],y
	AND.w #$007F
	CMP.w #$000C
	BCC .single
	CMP.w #$000F
	BCC .horizontal
	BEQ .map16
	CMP.w #$0070
	BCC .extendable
	INC.w !Index
	CMP.w #$007F
	BCC .rectangular
	JMP.w LongGroundObject

.special
	LDA.b [$FA],y
	AND.w #$007F
	PHA
	AND.w #$000F
	ASL A
	INY
	PHY
	TAY
	TXA
	TYX
	PLY
	CMP.w #$000E<<1
	BEQ ++
	INC.w !Index
	PLA
	REP 4 : LSR A
	CMP.w #$0007
	BEQ +
	JSL.l GroundObjects
	JMP.w LoadObject
	+
	JSL.l ExtraObjects
	JMP.w LoadObject
++
	PLA
	CMP.w #$0010
	BCC .smalltree
	CMP.w #$0020
	BCC .bigtree
	CMP.w #$0030
	BCC .smallcastle
	CMP.w #$0040
	BCC .bigcastle
	CMP.w #$0050
	BCC .stairs
	SEC
	SBC.w #$0050
	REP 4 : ASL A
	STA.w !objX
	JMP.w LoadObject


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Go to Object subrotuines
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.single
	JMP.w SingleTileObject

.map16
	JMP.w Map16Direct

.horizontal
	JMP.w HorizontalObject

.extendable
	JMP.w ExtendableObject

.rectangular
	JMP.w RectangularObject

.smalltree
	JMP.w SmallTreeObject

.bigtree
	JMP.w BigTreeObject

.smallcastle
	JSL.l SmallCastleObject
	JMP.w LoadObject

.bigcastle
	JSL.l BigCastleObject
	JMP.w LoadObject

.stairs
	JSL.l CastleSairsObject
	JMP.w LoadObject 


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Special functions
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpriteObjX:
	LDA.w !ScreenX
	REP 4 : ASL A
	RTS

SpriteObjY:
	TYA
	REP 3 : ASL A
	CLC
	ADC.b #$20
	RTS

FindSpriteSlot1:
	LDX.b #$00
-
	CLC
	LDA.b $10,x
	BEQ +
	INX
	CPX.b #$08
	BNE -
+
	RTS

FindSpriteSlot2:
	LDX.b #$08
-
	CLC
	LDA.b $10,x
	BEQ +
	DEX
	CPX.b #$FF
	BNE -
+
	RTS


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Objects with 1 Tile
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SingleTileObject:
	TAY
	LDA.w !lvlX
	CMP.w !objX
	BNE .end
	SEP #$30
	CPY.b #$07
	BPL ++
	CPY.b #$06
	BNE +
	LDA.w $075D
	BEQ .end
	STZ.w $075D
+
-
	LDA.w .tiles,y
	BRA +++
++
	LDA.b $5C
	DEC A
	BNE -
+
	LDA.w .tiles+5,y
+++
	STA.l !TileAddr,x
	LDA.b #$00
	STA.l !TileAddr+1,x
.end
	JMP.w LoadObject

.tiles
	incbin SMB1\Levels\Tiles\SingleTileObjects.bin


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Multiple Tiles with static length
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HorizontalObject:
	ASL A
	TAY
	LDA.w -2*$0C+.jumps,y
	STA.b !Scratch1
	JMP.w (!Scratch1)

.lpipe
	LDA.w !lvlX
	SEC
	SBC.w !objX
	BMI ++
	CMP.w #$0004
	BCS ++
	REP 2 : ASL A
	TAY
	CLC
	ADC.w #$0004
	STA.b !objW
-
	LDA.w .tiles,y
	AND.w #$00FF
	BEQ +
	STA.l !TileAddr,x
+
	REP 2 : INX
	INY
	CPY !objW
	BNE -
++
	JMP.w LoadObject
.tiles
	incbin SMB1\Levels\Tiles\L-Pipe.bin


.flagpole
	LDA.w !lvlX
	CMP.w !objX
	BNE ++
	SEP #$10
	CPX.b #!MapHeight-4*2
	BMI +
	LDX.b #!MapHeight-4*2
+
	TXY
	LDA.w #!FlagPoleBall
	STA.l !TileAddr,x
-
	REP 2 : INX
	LDA.w #!FlagPoleBar
	STA.l !TileAddr,x
	CPX.b #!MapHeight-2*2
	BNE -
	LDA.w #!FlagPoleBase
	STA.l !MapHeight-2*2+!TileAddr
.sprite
	SEP #$20
	JSR.w SpriteObjX
	SEC
	SBC.b #$08
	STA.w $021F
	LDA.w !ScreenP
	SBC.b #$00
	STA.b $7E
	JSR.w SpriteObjY
	CLC
	ADC.b #$10
	STA.w $23D
	LDA.b #$B0
	STA.w $010D
	LDA.b #$30
	STA.b $21	
	INC.b $15
	JSR.w FindSpriteSlot1
	STA.b $9E
	TAX
	LDA.b #$31
	STA.b $1C,x
	REP #$30
	LDA.w #$FFFF
	STA.w $0FB4
	STA.w $0FB6
++
	JMP.w LoadObject


.springboard
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w #!SpringBoardTop
	STA.l !TileAddr,x
	LDA.w #!SpringBoardBottom
	STA.l 2*$01+!TileAddr,x
	TXY
	SEP #$30
	JSR.w FindSpriteSlot1
	JSR.w SpriteObjX
	STA.w $021A,x
	LDA.w !ScreenP
	STA.b $79,x
	JSR.w SpriteObjY
	STA.w $0238,x
	STA.b $5E,x
	LDA.b #$32
	STA.b $1C,x
	LDY.b #$01
	STY.b $BC,x
	INC $10,x
+
	JMP.w LoadObject


.jumps
	dw .lpipe,.flagpole,.springboard


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Map16 Direct insertion
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Map16Direct:
	REP 3 : INC.w !Index
	INY
	LDA.b [$FA],y
	PHA
	REP 2 : INY
	LDA.b [$FA],y
	AND.w #$000F
	STA.b !objH
	LDA.b [$FA],y
	REP 4 : LSR A
	AND.w #$000F
	CLC
	ADC.w !objX
	STA.b !objW
	PLY
	JSR.w Map16Rect
	JMP.w LoadObject

Map16Rect:
	LDA.w !lvlX
	CMP.w !objX
	BMI +
	DEC A
	CMP.b !objW
	BPL +
	TYA
-
	STA.l !TileAddr,x
	REP 2 : INX
	DEC.b !objH
	BPL -
+
	RTS

Map16Horizontal:
	CLC
	ADC.w !objX
	STA.w !objW
	TYA
.set
	PHY
	LDY.w !lvlX
	CPY.w !objX
	BMI +
	DEY
	CPY.w !objW
	BPL +
	STA.l !TileAddr,x
+
	PLY
	RTS

Map16Vertical1:
	STA.l !TileAddr,x
	REP 2 : INX
	DEC.b !objH
	BPL Map16Vertical1
	RTS

Map16Vertical2:
	REP 2 : INX
	STA.l !TileAddr,x
	DEC.b !objH
	BPL Map16Vertical2
	RTS


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Tiles extendable by X or Y
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ExtendableObject:
	PHA
	AND.w #$000F
	STA.b !objH
	PLA
	AND.w #$0070
	REP 3 : LSR A
	TAY
	LDA.w -2*$01+.jumps,y
	STA.b $07
	JMP.w ($0007)


.canon
	LDA.w !lvlX
	CMP.w !objX
	BNE +++
	TXY
	LDA.w #!CanonHead
	STA.l !TileAddr,x
	DEC.b !objH
	BMI +
	REP 2 : INX
	LDA.w #!CanonNeck
	STA.l !TileAddr,x
	DEC.b !objH
	BMI +
	LDA.w #!CanonBody
	JSR.w Map16Vertical2
+
	SEP #$30
	LDX.w $026A
	JSR.w SpriteObjY
	STA.w $0277,x
	LDA.w !ScreenP
	STA.w $026B,x
	JSR.w SpriteObjX
	STA.w $0271,x
	INX
	CPX.b #$06
	BCC	++
	LDX.b #$00
++
	STX.w $026A
+++
	JMP.w LoadObject

	
.pipetiles
	incbin SMB1\Levels\Tiles\Pipes.bin
.pipe
	LDA.w !lvlX
	SEC
	SBC.w !objX
	BNE +
	LDA.b !objH
	AND.w #$0008
	STA.b !Scratch1
	BRA ++
+
	DEC A
	BNE +++
	INY
	STZ.b !Scratch1
++
	PHX
	LDA.b !objH
	AND.w #$0007
	STA.b !objH
	LDA.w -2*$02+.pipetiles,y
	AND.w #$00FF
	STA.l !TileAddr,x
	DEC.b !objH
	BMI +
	LDA.w -2+2*$02+.pipetiles,y
	AND.w #$00FF
	JSR.w Map16Vertical2
+
	PLY
	SEP #$30
	LDA.b !Scratch1
	BEQ +++
	JSR.w FindSpriteSlot2
	BCS +++
	JSR.w SpriteObjX
	CLC
	ADC.b #$08
	STA.w $021A,x
	LDA.w !ScreenP
	ADC.b #$00
	STA.b $79,x
	LDA.b #$01
	STA.b $BC,x
	STA.b $10,x
	JSR.w SpriteObjY
	STA.w $0238,x
	LDA.b #$0D
	STA.b $1C,x
	JSR.w $CB99
+++
	JMP.w LoadObject

.horizontaltiles
	incbin SMB1\Levels\Tiles\HorizontalObjects.bin

.bridge
	PHY
	REP 2 : INX
	LDY.w #!BridgeTile
	LDA.b !objH
	JSR.w Map16Horizontal
	PLY
	LDA.b !objH
	BEQ +++
	REP 2 : DEX
.horizontal
	TYA
	LSR A
	TAY
	PHY
	LDA.w -1*$04+.horizontaltiles,y
	AND.w #$00FF
	TAY
	LDA.b !objH
	JSR.w Map16Horizontal
	PLY
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w -1*$04+.horizontaltiles+3,y
	BRA ++
+
	CMP.b !objW
	BNE +++
	LDA.w -1*$04+.horizontaltiles+6,y
++
	AND.w #$00FF
	STA.l !TileAddr,x
+++
	JMP.w LoadObject

.jumps
	dw .canon,.pipe,.pipe,.bridge,.horizontal,.horizontal


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Rectangularly Expandable Object
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RectangularObject:
	PHA
	INY
	LDA.b [$FA],y
	REP 4 : LSR A
	AND.w #$000F
	STA.b !objH
	LDA.b [$FA],y
	AND.w #$000F
	STA.b !Scratch1
	CLC
	ADC.w !objX
	STA.b !objW
	PLA
	CMP.w #$007C
	BEQ .coin
	CMP.w #$007D
	BEQ .treeisland
	CMP.w #$007E
	BEQ .mushroomisland
	AND.w #$000F
	TAY
	CPY.w #$0007
	BMI +
	LDA.w .tiles+5,y
	AND.w #$00FF
	JSR.w Map16Horizontal_set
	REP 2 : INX
	DEC.b !objH
	BMI ++
+
	LDA.w .tiles,y
	AND.w #$00FF
	TAY
	JSR.w Map16Rect
++
	JMP.w LoadObject

.tiles
	incbin SMB1\Levels\Tiles\Rectangular.bin

.treeisland
	JMP.w GreenIslandObject

.mushroomisland
	JMP.w MushroomIslandObject

.coin
	SEP #$20
	LDA.b $5C
	BEQ +
	LDY.w #!StandardCoin
	BRA ++
+
	LDY.w #!WaterCoin
++
	JSR.w Map16Rect
	JMP.w LoadObject

IslandObjectCap:
	TAY
	LDA.w .islandtiles-$7D,y
	AND.w #$00FF
	JSR.w Map16Horizontal_set
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w .islandtiles-$7D+2,y
	BRA ++
+
	CMP.w !objW
	BNE +
	LDA.w .islandtiles-$7D+4,y
++
	AND.w #$00FF
	STA.l !TileAddr,x
+
	RTS

.islandtiles
	incbin SMB1\Levels\Tiles\IslandCap.bin

;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The Green Island (I hate this)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GreenIslandObject:
	JSR.w IslandObjectCap
	DEC.b !objH
	BMI .end2
	REP 2 : INX
	LDA.b !Scratch1
	CMP.w #$02
	BEQ .single
	BMI .end2
	LDA.w !objX
	PHA
	INC A
	STA.w !objX
	CLC
	ADC.b !Scratch1
	SEC
	SBC.w #$0008
	STA.b !objW
	LDY.w #!GreenIslandNeckTile
	JSR.w Map16Horizontal
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w #!GreenIslandNeckLeft
	BRA ++
+
	CMP.b !objW
	BNE +++
	LDA.w #!GreenIslandNeckRight
++
	STA.l !TileAddr,x
+++
	DEC.b !objH
	BMI .end1
	LDY.b !objH
	PHY
	REP 2 : INX
	PHX
	LDY.w #!GreenIslandBodyTile
	JSR.w Map16Rect
	PLX
	PLY
	STY.b !objH
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w #!GreenIslandBodyLeft
	BRA ++
+
	CMP.w !objW
	BNE .end1
	LDA.w #!GreenIslandBodyRight
++
	JSR.w Map16Vertical1
.end1
	PLA
	STA.w !objX
.end2
	JMP LoadObject
.single
	LDA.w !objX
	INC A
	CMP.w !lvlX
	BNE .end2
	LDA.w #!GreenIslandNeckSingle
	STA.l !TileAddr,x
	DEC.b !objH
	BMI .end2
	LDA.w #!GreenIslandBodySingle
	JSR.w Map16Vertical2
	BRA .end2


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The Mushroom Island
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MushroomIslandObject:
	JSR.w IslandObjectCap
	LDA.b !Scratch1
	LSR A
	CLC
	ADC.w !objX
	CMP.w !lvlX
	BNE +
	DEC.b !objH
	BMI +
	LDA.w #!RedIslandStemNeck
	STA.l 2*$01+!TileAddr,x
	DEC.b !objH
	BMI +
	REP 2 : INX
	LDA.w #!RedIslandStemBody
	JSR.w Map16Vertical2
+
	JMP.w LoadObject


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Long Horizontally Extendable Ground
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LongGroundObject:
	LDA.w !lvlX
	CMP.w !objX
	BMI +
	INY
	LDA.b [$FA],y
	AND.w #$00FF
	CLC
	ADC.w !objX
	CMP.w !lvlX
	BMI +
	LDA.w #!GroundTop
	STA.l !TileAddr,x
	LDA.w #!GroundBottom
	STA.l 2*$01+!TileAddr,x
	STA.l 2*$02+!TileAddr,x
	STA.l 2*$03+!TileAddr,x
+
	JMP.w LoadObject


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Tree scenery
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SmallTreeObject:
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w #!SmallTreeHead
	STA.l !TileAddr,x
	LDA.w #!TreeStemTile
	STA.l 2+!TileAddr,x
+
	JMP.w LoadObject

BigTreeObject:
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w #!BigTreeHeadTop
	STA.l !TileAddr,x
	LDA.w #!BigTreeHeadBottom
	STA.l 2+!TileAddr,x
	LDA.w #!TreeStemTile
	STA.l 4+!TileAddr,x
+
	JMP.w LoadObject

LongSpriteObjX:
	PHB
	PHK
	PLB
	JSR.w SpriteObjX
	PLB
	RTL

LongFindSpriteSlot:
	PHB
	PHK
	PLB
	JSR.w FindSpriteSlot1
	PLB
	RTL

LongMap16Rect:
	PHB
	PHK
	PLB
	JSR.w Map16Rect
	PLB
	RTL

LongMap16Horizontal_set:
	PHB
	PHK
	PLB
	JSR.w Map16Horizontal_set
	PLB
	RTL

LongMap16Vertical1:
	PHB
	PHK
	PLB
	JSR.w Map16Vertical1
	PLB
	RTL

LongMap16Vertical2:
	PHB
	PHK
	PLB
	JSR.w Map16Vertical2
	PLB
	RTL

LongWarpZoneTextJump:
	PHB
	PHK
	PLB
	JSR.w $90FC
	PLB
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This routine existed in the original
;; level ASM code, but was called only
;; outside of it. Because of this, removing
;; it would cause crashes. It may be smart
;; to put it somewhere else, but there's
;; really no need to so long as there is
;; still room here. The name is derived
;; from it's original SNES location
;; because I really don'T know what it
;; does yet.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE03ACF6_table1:
	db $00,$D0
CODE03ACF6_table2:	
	db $05,$05
CODE03ACF6:
	PHA
	REP 4 : LSR A
	TAY
	LDA .table2,y
	STA $07
	PLA
	AND #$0F
	CLC
	ADC .table1,y
	STA $06
	RTS


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; End-of-level Castles
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $05EE66
SmallCastleObject:
	PHB
	PHK
	PLB
	STZ.b !Scratch1
	LDA.w #$0000
	LDY.w !objX
-
	CPY.w !lvlX
	BEQ +
	INY
	INC.b !Scratch1
	CLC
	ADC.w #!BigCastleHeight
	CMP.w #!BigCastleHeight*!SmallCastleWidth
	BMI -
	PLB
	RTL
+
	TAY
	LDA.w #!SmallCastleHeight-1
	STA.b !objH
-
	LDA.w 2*!BigCastleHeight+BigCastleObject_tiles,y
	AND.w #$00FF
	BEQ +
	STA.l !TileAddr,x
+
	REP 2 : INX
	INY 
	DEC.b !objH
	BPL -
	JMP CastleFlagSprite


BigCastleObject:
	PHB
	PHK
	PLB
	LDA.w #-$02
	STA.b !Scratch1
	LDA.w #$0000
	LDY.w !objX
-
	CPY.w !lvlX
	BEQ +
	INY
	INC.b !Scratch1
	CLC
	ADC.w #!BigCastleHeight
	CMP.w #!BigCastleHeight*!BigCastleWidth
	BMI -
	PLB
	RTL
+
	TAY
	LDA.w #!BigCastleHeight-1
	STA.b !objH
-
	LDA.w .tiles,y
	AND.w #$00FF
	BEQ +
	STA.l !TileAddr,x
+
	REP 2 : INX
	INY 
	DEC.b !objH
	BPL -
	JMP CastleFlagSprite

.tiles
	incbin SMB1\Levels\Tiles\Castle.bin

CastleFlagSprite:
	SEP #$30
	LDA.b !Scratch1
	CMP #$03
	BMI ++
	BNE +
	PHX
	JSL.l LongFindSpriteSlot
	LDA $0726
	REP 4 : ASL A
	SEC
	SBC.b #$08
	STA.w $021A,x
	LDA.w $0725
	ADC.b #$00
	STA.b $79,x
	LDA.b #$01
	STA.b $BC,x
	STA.b $10,x
	LDA.b #$90
	STA.w $0238,x
	LDA.b #$31
	STA.b $1C,x
	INC.w $0EE7
	PLX
	BEQ +
	INC $0EE7
+
	REP #$20
	LDA.l $0B<<1+!TileAddr
	CMP.w #$0056
	BNE ++
	LDA.w #$0064
	STA.l $0B<<1+!TileAddr
++
	PLB
	RTL
	

;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The beginning staircase of castles
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CastleSairsObject:
	PHB
	PHK
	PLB
	STX.b !Scratch1
	LDA.w #$0000
	TAX
	LDY.w !objX
-
	CPY.w !lvlX
	BEQ +
	INY
	INX
	CPX.w #!CastleStairsWidth
	BMI -
	PLB
	RTL
+
	SEP #$10
	LDY.w .offset,x
	LDX.b !Scratch1
	LDA.w #!CastleStairsHeight-1
	STA.b !objH
-
	LDA.w .tiles,y
	AND.w #$00FF
	BEQ +
	STA.l !TileAddr,x
+
	REP 2 : INX
	INY 
	DEC.b !objH
	BPL	-
	PLB
	RTL
.tiles
	incbin SMB1\Levels\Tiles\CastleStairs.bin
.offset
	db $00,$00,$00,$05,$04,$03


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Objects related to ground tiles
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GroundObjects:
	PHB
	PHK
	PLB
	PHA
	LDA.b [$FA],y
	AND.w #$000F
	STA.b !objH
	LDA.b [$FA],y
	REP 4 : LSR A
	AND.w #$000F
	CLC
	ADC.w !objX
	STA.b !objW
	PLA
	CMP.w #$0006
	BEQ .ceiling
	LDY #$0000
	CMP.w #$0003
	BMI +
	SEC
	SBC.w #$0003
	INY
+
	PHA
	JSR.w .ground
	PLA
	BNE +
	JSR.w .left
	PLB
	RTL
+
	DEC A
	BNE +
	JMP.w .right
+
	JMP.w .both

.ceiling
	LDA.w !lvlX
	CMP.w !objX
	BMI +
	DEC A
	CMP.w !objW
	BPL +
	AND.w #$0001
-
	EOR.w #$0001
	TAY
	LDA.w .tiles+$10,y
	AND.w #$00FF
	STA.l !TileAddr,x
	TYA
	REP 2 : INX
	DEC.b !objH
	BPL -
+
	PLB
	RTL

.left
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w .tiles+4,y
	AND.w #$00FF
	STA.l !TileAddr,x
	DEC.b !objH
	BMI +
	LDA.w .tiles+$08,y
	AND.w #$00FF
	JSL.l LongMap16Vertical2
+
	RTS

.right
	LDA.w !lvlX
	DEC A
	CMP.w !objW
	BNE +
	LDA.w .tiles+6,y
	AND.w #$00FF
	STA.l !TileAddr,x
	DEC.b !objH
	BMI +
	LDA.w .tiles+$0A,y
	AND.w #$00FF
	JSL.l LongMap16Vertical2
+
	PLB
	RTL

.ground
	LDA.b !objH
	PHA
	LDA.w .tiles,y
	AND.w #$00FF
	JSL.l LongMap16Horizontal_set
	DEC.b !objH
	BMI +
	PHX
	REP 2 : INX
	LDA.w .tiles+2,y
	AND.w #$00FF
	PHY
	TAY
	JSL.l LongMap16Rect
	PLY
	PLX
+
	PLA
	STA.b !objH
	RTS

.both
	LDA.w !objX
	CMP.w !objW
	BEQ +
	JSR.w .left
	JMP.w .right
+
	CMP.w !lvlX
	BNE +
	LDA.w .tiles+$0C,y
	AND.w #$00FF
	STA.l !TileAddr,x
	DEC.b !objH
	BMI +
	LDA.w .tiles+$0E,y
	AND.w #$00FF
	JSL.l LongMap16Vertical2
+
	PLB
	RTL

.tiles
	incbin SMB1\Levels\Tiles\GroundObjects.bin


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Extra objects which just had no room anywhere else.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ExtraObjects:
	PHB
	PHK
	PLB
	LDA.b [$FA],y
	AND.w #$000F
	STA.b !objH
	CLC
	ADC.w !objX
	STA.b !objW
	LDA.b [$FA],y
	REP 4 : LSR A
	AND.w #$000F
	ASL A
	TAY
	LDA.w .jumps,y
	STA.b !Scratch1
	JMP.w (!Scratch1)

.jumps
	dw .leftedgebottom,.rightedgebottom,.leftbottom,.rightbottom
	dw .singleedgebottomboth,.singleedgebottomleft,.singleedgebottomright
	dw .singlebottomboth,.singlebottomleft,.singlebottomright
	dw .questionblocks,.bowserbridge,.ceilingcap,.liftrope,.longlpipe,.staircase

.leftedgebottom
.rightedgebottom
.leftbottom
.rightbottom
.singleedgebottomboth
.singleedgebottomleft
.singleedgebottomright
.singlebottomboth
.singlebottomleft
.singlebottomright

.questionblocks
	LDA.w #!QuestionBlockRowTile
	BRA +
.bowserbridge
	LDA.w #!BowserBridge
+
	JSL.l LongMap16Horizontal_set
	PLB
	RTL

.ceilingcap
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w #!CeilingCapTile
-
	STA.l !TileAddr,x
	REP 4 : INX
	REP 2 : DEC.b !objH
	BPL -
+
	PLB
	RTL

.liftrope
	LDA.w !lvlX
	CMP.w !objX
	BNE +
	LDA.w #!VerticalLiftRopeTile
	JSL.l LongMap16Vertical1
	LDA.w #!VerticalLiftRopeAir
-
	STA.l !TileAddr,x
	REP 2 : INX
	CPX.w #!MapHeight+1<<1
	BNE -
+
	PLB
	RTL

.longlpipe
	LDA.w !lvlX
	SEC
	SBC.w !objX
	BMI +++
	CMP.w #$0004
	BPL +++
	TAY
-
	LDA.w .tiles,y
	AND.w #$00FF
	BEQ +
	STA.l !TileAddr,x
+
	DEC.b !objH
	BMI ++
	REP 2 : INX
	BRA -
++
	LDA.b !Scratch2
	BEQ +
	LDA.w .tiles+4,y
	AND.w #$00FF
	STA.l !TileAddr-2,x
+
	LDA.w .tiles+8,y
	AND.w #$00FF
	STA.l !TileAddr,x
+++
	PLB
	RTL

.tiles
	incbin SMB1\Levels\Tiles\LongL-Pipe.bin

.staircase
	LDA.w !lvlX
	SEC
	SBC.w !objX
	BMI ++
	CMP.b !objH
	BPL ++
	CMP.w #!StaircaseHeight+1
	BEQ +
	BPL ++
	STA.b !Scratch1
	LDA.w #!StaircaseHeight
	SEC
	SBC.w !Scratch1
	STA.b !Scratch2
	TXA
	LSR A
	CLC
	ADC.b !Scratch2
	ASL A
	TAX
-
	LDA.w #!StaircaseTile
--
	STA.l !TileAddr,x
	REP 2 : INX
	DEC.b !Scratch1
	BPL --
	PLB
	RTL
+
	LDA.w #!StaircaseHeight
	STA.b !Scratch1
	BRA -
++
	PLB
	RTL


ORG $048E15
	fillbyte $FF : fill $3C8
ORG $048E15
LevelCommands:
	PHB
	PHK
	PLB
	LDA.b [$FA],y
	AND.w #$000F
	ORA.w !objX
	CMP.w !lvlX
	BEQ +
	PLB
	RTL
+
	LDA.b [$FA],y
	REP 4 : LSR A
	AND.w #$0007
	TAX
	ASL A
	TAY
	LDA.w .jumps,y
	STA.b !Scratch1
	SEP #$30
	JMP.w (!Scratch1)

.sprites
	db $14,$17,$18

.generator
	LDA.w .sprites,x
	LDY.b #$09
-
	DEY
	BMI +
	CMP.w $001C,y
	BNE -
	LDA.b #$00
+
	STA.w $06CD
	PLB
	RTL

.warpzone
	LDX.b #$04
	LDA.w $075F
	BEQ +
	INX
	LDY.b $5C
	DEY
	BNE +
	INX
+
	TXA
	STA.w $06D6
	JSL.l LongWarpZoneTextJump
	LDA.b #$0D
	STA.b !Scratch1
	LDA.b #$00
	LDX.b #$08
-
	LDY.b $1C,x
	CPY.b !Scratch1
	BNE +
	STA.b $10,x
+
	DEX
	BPL -

.scrollstop
	LDA.w $0723
	EOR.b #$01
	STA.w $0723
	PLB
	RTL

.jumps
	dw .generator,.generator,.generator,.scrollstop,.warpzone