;;--------------------------------------------------------------------
;; sjasmplus setup
;;--------------------------------------------------------------------

	; Allow Next paging and instructions
	DEVICE ZXSPECTRUMNEXT
	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

	; Generate a map file for use with Cspect
	CSPECTMAP "build/test.map"


;;--------------------------------------------------------------------
;; program
;;--------------------------------------------------------------------

	ORG $8000

LAYER2_16K_BANK = 9
LAYER2_8K_BANK = LAYER2_16K_BANK * 2
BANK_SIZE_8K = 8192
BANK_SIZE_8K_H = BANK_SIZE_8K / 256
RES_X = 320
RES_Y = 256
LAYER_2_8K_BANKS = RES_X * RES_Y / BANK_SIZE_8K

start:
  JP main

  INCLUDE "init.asm"
  INCLUDE "palette.asm"
  INCLUDE "clearScreen.asm"
  INCLUDE "screen.asm"

main:
  ; JP main
  CALL initPalette
  CALL initLayer2
  CALL clearScreen
  CALL drawScreen
  CALL updatePalette

.infiniteLoop:
	JR .infiniteLoop

;;--------------------------------------------------------------------
;; variables / data
;;--------------------------------------------------------------------

square:
  INCBIN square.bin

;;--------------------------------------------------------------------
;; Set up .nex output
;;--------------------------------------------------------------------

	; This sets the name of the project, the start address,
	; and the initial stack pointer.
	SAVENEX OPEN "build/test.nex", start, $ff40

	; This asserts the minimum core version.  Set it to the core version
	; you are developing on.
	SAVENEX CORE 3,0,6

	; This sets the border colour while loading (in this case white),
	; what to do with the file handle of the nex file when starting (0 =
	; close file handle as we're not going to access the project.nex
	; file after starting.  See sjasmplus documentation), whether
	; we preserve the next registers (0 = no, we set to default), and
	; whether we require the full 2MB expansion (0 = no we don't).
	SAVENEX CFG 7,0,0,0

  SAVENEX AUTO

  SAVENEX CLOSE
