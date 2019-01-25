; <copyright file="Tables.asm" company="Public Domain">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; THIS IS A FUNDAMENTAL DATA FILE. DO NOT MODIFY IT!
;;
;; Changes are automatically made to this file by
;; MushROMs during GFX events when needed.
;;
;; The custom GFX routine is designed to choose
;; which GFX files go to which sections of the
;; level's GFX. These tables dictate which GFX files
;; are chosen for which section. Why ObjGFX_Table3 is
;; out of order has to do with a special property it
;; contains. Examine the main GFX.asm file for info.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG !GFX_Tables
GFX_Table1:
SprtGFX_Table1:
incbin SMB1\GFX\Tables\Sprite1.bin

SprtGFX_Table2:
incbin SMB1\GFX\Tables\Sprite2.bin

SprtGFX_Table3:
incbin SMB1\GFX\Tables\Sprite3.bin

SprtGFX_Table4:
incbin SMB1\GFX\Tables\Sprite4.bin

ObjGFX_Table1:
incbin SMB1\GFX\Tables\Object1.bin

ObjGFX_Table2:
incbin SMB1\GFX\Tables\Object2.bin

ObjGFX_Table4:
incbin SMB1\GFX\Tables\Object4.bin

ObjGFX_Table5:
incbin SMB1\GFX\Tables\Object5.bin

ObjGFX_Table3:
incbin SMB1\GFX\Tables\Object3.bin
