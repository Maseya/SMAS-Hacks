;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; THIS IS A FUNDAMENTAL DATA FILE. DO NOT MODIFY IT!
;;
;; Changes are automatically made to this file by
;; MushROMs during GFX events when needed.
;;
;; This is a small data file which MushROMs uses to
;; determine what certain default GFX will be used for
;; certain events, like levels with no GFX selection,
;; Player GFX, or animation. This file is also used by
;; the game itself.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitGFX_Table1:
dw $0000,$0001,$0002,$0003,$0018,$0008,$0009,$000A,$000B
InitGFX_Table2:
dw $1000,$1800,$2000,$2800,$3000,$6000,$6800,$7000,$7800

AnimGFX_Table1:
dw !AnimGFX1,!AnimGFX2,!AnimGFX3,!AnimGFX4
AnimGFX_Table2:
dw $0004,$0005,$0006,$0007

GFX_Table2:
dw $6000,$6800,$7000,$7800
dw $1000,$1800,$2800,$3000
GFX_Table3:
dw $0008,$0009,$000A,$000B
dw $0000,$0001,$0003,$0018

PlayerGFX_Table1:
dw !PlayerGFX1,!PlayerGFX2
PlayerGFX_Table2:
dw $001C,$001D,$0020,$0021
