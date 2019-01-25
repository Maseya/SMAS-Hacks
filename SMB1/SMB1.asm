; <copyright file="SMB1.asm" company="Public Domain">
;     Copyright (c) 2019 Nelson Garcia. All rights reserved. Licensed under
;     GNU Affero General Public License. See LICENSE in project root for full
;     license information, or visit https://www.gnu.org/licenses/#AGPL
; </copyright>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The SMAS SMB1 ASM hack core! All code (for the SMB1 portion)
;; begins here. I have done	A LOT to this game. Far too much
;; to put in one file. I attempted to organize all the files
;; as logically as possible. No actual code is executed here.
;; However, the primary code branches are created from this
;; file. Each of the branches will likely have more subranches.
;; These files could include some extra code, BIN files, or
;; large tables. The design of MushROMs will read some of
;; the tables and BIN files to extract data. All table files
;; that MushROMs will use will state that it is a fundamental
;; data file and should not be edited. All other ASM files, you
;; are free to modify at will. Just note that any integral
;; changes you make will likely not appear in the editor. This
;; is the primary reason why I plan to make MushROMs open source.
;;
;; Code �2009-2012 spel werdz rite (SWR)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; It's a good idea to keep these files in the order
;; they are given. Some routines from later files may
;; depend on variables from files that preceed it.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
incsrc SMB1\defs.asm
incsrc SMB1\Maps\Maps.asm
incsrc SMB1\Levels\Levels.asm
incsrc SMB1\Map16\Map16.asm
incsrc SMB1\Palette\Palette.asm
incsrc SMB1\GFX\GFX.asm
