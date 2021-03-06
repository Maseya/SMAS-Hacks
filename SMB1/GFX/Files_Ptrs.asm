; <copyright file="Files_Ptrs.asm" company="Public Domain">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; THIS IS A FUNDAMENTAL DATA FILE. DO NOT MODIFY IT!
;;
;; Changes are automatically made to this file by
;; MushROMs during GFX events when needed.
;;
;; Having all the pointers is useless unless they are
;; physcially written to the ROM. This file takes care
;; of that. Incidentally, the default spot chosen used
;; to contain GFX but now is $3000 bytes of free space.
;; So there is not much need to change the location unless
;; some expansion project is planned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ORG !GFX_Pointers
GFX_Lo:
db !GFX000Lo,!GFX001Lo,!GFX002Lo,!GFX003Lo,!GFX004Lo,!GFX005Lo,!GFX006Lo,!GFX007Lo,!GFX008Lo,!GFX009Lo,!GFX00ALo,!GFX00BLo,!GFX00CLo,!GFX00DLo,!GFX00ELo,!GFX00FLo
db !GFX010Lo,!GFX011Lo,!GFX012Lo,!GFX013Lo,!GFX014Lo,!GFX015Lo,!GFX016Lo,!GFX017Lo,!GFX018Lo,!GFX019Lo,!GFX01ALo,!GFX01BLo,!GFX01CLo,!GFX01DLo,!GFX01ELo,!GFX01FLo
db !GFX020Lo,!GFX021Lo,!GFX022Lo,!GFX023Lo,!GFX024Lo,!GFX025Lo,!GFX026Lo,!GFX027Lo,!GFX028Lo,!GFX029Lo,!GFX02ALo,!GFX02BLo

ORG !GFX_Pointers+$1000
GFX_Hi:
db !GFX000Hi,!GFX001Hi,!GFX002Hi,!GFX003Hi,!GFX004Hi,!GFX005Hi,!GFX006Hi,!GFX007Hi,!GFX008Hi,!GFX009Hi,!GFX00AHi,!GFX00BHi,!GFX00CHi,!GFX00DHi,!GFX00EHi,!GFX00FHi
db !GFX010Hi,!GFX011Hi,!GFX012Hi,!GFX013Hi,!GFX014Hi,!GFX015Hi,!GFX016Hi,!GFX017Hi,!GFX018Hi,!GFX019Hi,!GFX01AHi,!GFX01BHi,!GFX01CHi,!GFX01DHi,!GFX01EHi,!GFX01FHi
db !GFX020Hi,!GFX021Hi,!GFX022Hi,!GFX023Hi,!GFX024Hi,!GFX025Hi,!GFX026Hi,!GFX027Hi,!GFX028Hi,!GFX029Hi,!GFX02AHi,!GFX02BHi

ORG !GFX_Pointers+$2000
GFX_Bk:
db !GFX000Bk,!GFX001Bk,!GFX002Bk,!GFX003Bk,!GFX004Bk,!GFX005Bk,!GFX006Bk,!GFX007Bk,!GFX008Bk,!GFX009Bk,!GFX00ABk,!GFX00BBk,!GFX00CBk,!GFX00DBk,!GFX00EBk,!GFX00FBk
db !GFX010Bk,!GFX011Bk,!GFX012Bk,!GFX013Bk,!GFX014Bk,!GFX015Bk,!GFX016Bk,!GFX017Bk,!GFX018Bk,!GFX019Bk,!GFX01ABk,!GFX01BBk,!GFX01CBk,!GFX01DBk,!GFX01EBk,!GFX01FBk
db !GFX020Bk,!GFX021Bk,!GFX022Bk,!GFX023Bk,!GFX024Bk,!GFX025Bk,!GFX026Bk,!GFX027Bk,!GFX028Bk,!GFX029Bk,!GFX02ABk,!GFX02BBk
