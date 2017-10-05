;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; THIS IS A FUNDAMENTAL DATA FILE. DO NOT MODIFY IT!
;;
;; Changes are automatically made to this file by
;; MushROMs during level events.
;;
;; This is a data file used by MushROMs to get level-
;; related data like number of worlds, levels per world,
;; level numbers, and map pointers.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG $04BF00
MaxWorlds:
incbin SMB1\Maps\Tables\MaxWorlds.bin

MaxLevels:
incbin SMB1\Maps\Tables\MaxLevels.bin

ORG $04C000
Maps:
incbin SMB1\Maps\Tables\Maps.bin