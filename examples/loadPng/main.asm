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
  ; Enhanced ULA Control $43
  ; Bit Effect
  ; 7   1 to disable palette index auto-increment, 0 to enable
  ; 6-4 Selects palette for read or write
  ;     000 / 100 ULA first / second palette
  ;     001 / 101 Layer 2 first / second palette
  ;     010 / 110 Sprites first / second palette
  ;     011 / 111 Tilemap first / second palette
  NEXTREG $43, %00010000

  ; Palette Index $40
  ; Reads / writes palette colour index to be manipluated
  NEXTREG $40, 0
loop:
  ; Enhanced ULA Palette Extension $44
  ; Reads or writes 9 bit colour definition in two read / writes
  ; First read / write:
  ; Bit Field
  ; 7-5 R
  ; 4-2 G
  ; 1-0 B2-B1
  ; Second read / write:
  ; Bit Field
  ; 7   Layer 2 Priority (if 1 this colour is on top)
  ; 6-1 Reserved, set to 0
  ; 0   B0
  LD A, (HL)
  INC HL
  NEXTREG $44, A
  LD A, (HL)
  INC HL
  NEXTREG $44, A
  DJNZ copy9BitPalette
  RET

initLayer2:
  ; Layer 2 Access Port $123B
  ; Bit Effect
  ; 7-6 Video RAM bank select
  ;     00 First 16K of layer 2 in the bottom 16K slot
  ;     01 Second 16K of layer 2 in the bottom 16K slot
  ;     10 Third 16K of layer 2 in the bottom 16K slot
  ;     11 First 48K of layer 2 in the bottom 48K - 16K slots 0-2 (core 3.0+)
  ; 5   Reserved, use 0
  ; 4   0 (1 for extra options since core 3.0.7)
  ; 3   Use Shadow Layer 2 for paging
  ;     0 Map Layer 2 RAM Page $12
  ;     1 Map Layer 2 RAM Shadow Page #13
  ; 2   Enable Layer 2 read-only paging on 16K slot 0 (core 3.0+)
  ; 1   Layer 2 visible (mirrored in Display Control 1 $69)
  ; 0   Enable Layer 2 write-only paging on 16K slot 0
  LD BC, $123B
  LD A, %00000010
  OUT (C), A

  ; Layer 2 RAM Page $12
  ; Bit Effect
  ; 7   Reserved, must be 0
  ; 6-0 Starting 16K bank of Layer 2
  NEXTREG $12, LAYER2_16K_BANK

  ; Layer 2 Control $70
  ; Bit Effect
  ; 7-6 Reserved, must be 0
  ; 5-4 Layer 2 resolution (0 after soft reset)
  ;     00 256x192 8BPP
  ;     01 320x256 8BPP
  ;     00 640x256 4BPP
  ; 3-0 Palette offset (0 after soft reset)
  NEXTREG $70, %00010000

  ; Clip Window Control $1C (Write)
  ; Bit Effect
  ; 7-4 Reserved, must be 0
  ; 3   1 to reset Tilemap clip-window register index
  ; 2   1 to reset ULA/LoRes clip-window register index
  ; 1   1 to reset Sprite clip-window register index
  ; 0   1 to reset Layer 2 clip-window register index
  NEXTREG $1C, 1

  ; Clip Window Layer 2 $18
  ; Bits 7-0 Read / writes clip-window co-ordinates for Layer 2
  ; 4 writes to write co-ordinates, in order: X1, X2, Y1, Y2
  ; Positions are inclusive
  ; X positions doubled for 320x256 mode
  ; X positions quadrupled for 640x256 mode
  NEXTREG $18, 0
  NEXTREG $18, RES_X / 2 - 1
  NEXTREG $18, 0
  NEXTREG $18, RES_Y - 1
  RET

loadImage:


main:
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
