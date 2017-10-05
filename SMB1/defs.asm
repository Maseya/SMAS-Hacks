;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; I've made several new routines and tables which
;; are too big for their original locations. This
;; file includes lists of variables and addresses of
;; where their routines start. Each one includes a
;; comment of what it is used for. You're free to change
;; these locations. However, be wary of how much space
;; is used.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Addresses of routines 
;; involving Palettes go here.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
!Palette_Files = $408000		;Table of all Palettes for levels in SMB1 (0x20000 bytes).



;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Addresses of routines
;; involving GFX go here.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
!GFX_LZ2RAM = $7E6000			;The RAM location where the LZ2 compression routine will be stored
!GFX_ASM = $088000				;Stores where the custom GFX routine is stored.
!GFX_Tables = $068000			;Stores the pointers of which GFX file to load (0x2400 bytes).
!GFX_Pointers = $0CD000			;Stores the pointers of all 0x1000 GFX Files (0x3000 bytes).
!GFX_Files = $608000			;All GFX data will be stored at this address.



;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Addresses of routines
;; involving levels\map16 go here.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
!Map16_Tiles = $448000			;Address of the full map16 tile data (0x8000 bytes).
!Map16_ActsLike = $0AE000		;Address of the full "tile acts like" data (0x2000 bytes).