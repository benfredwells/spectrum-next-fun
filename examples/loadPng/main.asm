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

PALETTE_SIZE EQU 128
LAYER2_16K_BANK EQU 9
RES_X = 320
RES_Y = 256

start:
  JP main

copy9BitPalette:
  LD A, (HL)
  INC HL
  NEXTREG $44, A
  LD A, (HL)
  INC HL
  NEXTREG $44, A
  DJNZ copy9BitPalette
  RET

initLayer2:
  ; enable layer 2 by setting bit 1 of Layer 2 Access Port $123B
  ; https://wiki.specnext.dev/Layer_2
  LD BC, $123B
  LD A, 2
  OUT (C), A

  ;; setup starting 16k bank for layer2. $12 is only used for this.
  NEXTREG $12, LAYER2_16K_BANK

  ; set 320x256 mode ny writing.
  ; writing 0 to low order bits of $70 also sets palette offset to 0
  NEXTREG $70, %00010000

  ; setup clip window for this resolution
  NEXTREG $1C, 1
  NEXTREG $18, 0
  NEXTREG  $18 RESOLUTION_X / 2 - 1
  RET

main:
  ; prepare system and parameters to copy palette
  NEXTREG $43, %00010000  ; Auto increment. Layer 2 first palette for read/write
  NEXTREG $40, 0          ; Start copying into index 0
  LD HL, palette
  LD B, PALETTE_SIZE
  CALL copy9BitPalette
  CALL initLayer2


.infiniteLoop:
	JR .infiniteLoop

	RET

;;--------------------------------------------------------------------
;; data
;;--------------------------------------------------------------------

palette:
	INCBIN "palette.bin"

;;--------------------------------------------------------------------
;; Set up .nex output
;;--------------------------------------------------------------------

	; This sets the name of the project, the start address,
	; and the initial stack pointer.
	SAVENEX OPEN "build/test.nex", start, $ff40

	; This asserts the minimum core version.  Set it to the core version
	; you are developing on.
	SAVENEX CORE 2,0,0

	; This sets the border colour while loading (in this case white),
	; what to do with the file handle of the nex file when starting (0 =
	; close file handle as we're not going to access the project.nex
	; file after starting.  See sjasmplus documentation), whether
	; we preserve the next registers (0 = no, we set to default), and
	; whether we require the full 2MB expansion (0 = no we don't).
	SAVENEX CFG 7,0,0,0

	; Generate the Nex file automatically based on which pages you use.
	SAVENEX AUTO
