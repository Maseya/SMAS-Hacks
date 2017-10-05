;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is a very small hack which will basically let us expand
;; the Map16 tile data.
;;
;; Code ?2009-2010 spel werdz rite (SWR)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $039273
	REP $25 : NOP

ORG $039273
	LDA.b #!Map16_Tiles>>$10
	STA.b $08
	REP #$30
	TXA
	AND.w #$00FF
	PHA
	ASL A
	TAX
	LDA.l !TileAddr,x
	REP 3 : ASL A
	STA.b $03
	LDA.w #!Map16_Tiles
	STA.b $06
	PLX

ORG $0392A8
	LDA.b [$06],y

ORG $0392AF
	LDA.b [$06],y

ORG $03930A
	REP $26 : NOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Inserts the Map16 tile data
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG !Map16_Tiles
	incbin SMB1\Map16\Default\Map16G.bin


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Inserts the Map16 "Tile Acts
;; Like" properties to a user-
;; defined location.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG !Map16_ActsLike
ExMap16Set:
	incbin SMB1\Map16\Default\Map16.bin