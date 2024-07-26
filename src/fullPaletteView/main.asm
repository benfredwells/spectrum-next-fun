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

GRID_SIZE = 8

BG_COLOUR = 0
FG_COLOUR = 1

start:
  JP main

initPalette:
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
  ; Reads / writes palette colour index to be manipulated
  NEXTREG $40, 0
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
  ;
  ; For now, set two colours, black and blue
  ; First black: first 0, second 0
  LD A, 0
  NEXTREG $44, A
  LD A, 0
  NEXTREG $44, A
  ; Second blue: first %00000011, second %00000001
  LD A, %00000011
  NEXTREG $44, A
  LD A, %00000001
  NEXTREG $44, A
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

; In 320x256 mode, pixels are arranged in memory in the vertical lines. i.e.
; offset   0 is (0, 0), offset   0 is (0, 1)
; offset 256 is (1, 0), offset 257 is (2, 1)
; This is spread over 5 8K banks.
; Uses these registers:
; C: Layer 2 (destination) Bank
; DE: Write address

clearScreen:
  ; Initialize bank
  LD C, LAYER2_8K_BANK
.loadBank:
  LD A, C
  ; Memory Management Slot 6 Bank $56
  ; Contains the 8K bank address for Slot 6
  NEXTREG $56, A

  ; Move write pointer to the start of Slot 6
  LD DE, $C000
.writePixel:
  LD A, BG_COLOUR
  LD (DE), A
  ; Inc DE in two steps so we can test each byte
  INC E
  ; If E is non-zero we can't be at the end of the bank
  JR NZ, .writePixel
  ; If E is zero we need to INC D and check where we are
  INC D
  LD A, D
  AND %00111111
  CP BANK_SIZE_8K_H
  JP NZ, .writePixel

  ; We need to change bank, unless we're done
  INC C
  LD A, C
  CP LAYER2_8K_BANK + LAYER_2_8K_BANKS
  JP NZ, .loadBank
  RET

; Call with C holding the x offset (where 1 offset == 16 pixels)
; and B holding the Y offset (where 1 offset == 32 pixels)
; B and C will be restored upon return
drawSquare:
  ; local variables
  ; the x / y offsets of the grid as a whole
.startx
  BYTE 0
.starty
  BYTE 0
  ; the current x / y position within the grid
.gridx
  BYTE 0
.gridy
  BYTE 0
.start
  PUSH BC
  LD HL, 0
  LD (.startx), HL
  LD (.gridx), HL
  ; Initialize bank. Due to the way this is called (currently) we can rely on
  ; all columns being in the same bank, so we just need to look at the starting
  ; x offset. Each bank covers 32 columns, which is 2 "offsets".
  LD A, C
  SRL A
  LD D, LAYER2_8K_BANK
  ADD A, D
  ; Memory Management Slot 6 Bank $56
  ; Contains the 8K bank address for Slot 6
  NEXTREG $56, A

  ; Find the start offsets
  LD A, C
  AND %00000001
  SLA A
  SLA A
  SLA A
  LD (.startx), A
.writeVerticalLine
  ; load the square start from data
  LD HL, square_start_ys
  LD BC, 0
  LD A, (.gridx)
  LD C, A
  ADD HL, BC
  LD A, (HL)
  ; jump ahead those many pixels
  LD (.gridy), A
.writePixel:
  LD A, (.gridy)
  LD B, A
  LD A, (.gridx)
  LD C, A
  ; add the slot offset to have DE point into the screen buffer, and the
  ; start offsets as well
  LD A, (.startx)
  ADD A, C
  OR %11000000
  LD D, A
  LD E, B
  LD A, FG_COLOUR
  LD (DE), A
  INC B
  LD A, B
  LD (.gridy), A
  ; load the size for this column
  LD HL, square_stop_ys
  LD BC, 0
  LD A, (.gridx)
  LD C, A
  ADD HL, BC
  LD A, (HL)
  SBC A, E
  ; If we have done square_sizes[column] pixels we're done
  JR NZ, .writePixel
  INC C
  LD A, C
  LD (.gridx), A
  LD A, GRID_SIZE
  SBC A, C
  JR NZ, .writeVerticalLine
  POP BC
  RET

main:
  CALL initPalette
  CALL initLayer2
  CALL clearScreen

  ; first draw control square at offset 1
  LD BC, $0001
  CALL drawSquare.start
  ; then draw 8 palette squares at offset 4, 6 ... 18
  LD BC, $0004

.paletteloop
  CALL drawSquare.start
  INC C
  INC C
  LD A, 18
  SBC A, C
  JR NZ, .paletteloop

.infiniteLoop:
	JR .infiniteLoop

	RET

;;--------------------------------------------------------------------
;; variables / data
;;--------------------------------------------------------------------

; square_starts - an array of y offsets of the start of the square
;  - i.e. for each column of pixels in the grid, what is the y offset
;  - of the topmost pixel
;  - there need to be GRID_SIZE of these and each one is < GRID_SIZE
square_start_ys:
  BYTE $02,$01,$00,$00,$00,$00,$01,$02

; square_lengths - an array of y pixel counts for the square
;  - i.e. how many pixels are in each column of pixels in the grid
;  - there need to be GRID_SIZE of these and the sum of this and
;    square_starts needs to be < GRID_SIZE+1
square_stop_ys:
  BYTE $07,$08,$09,$09,$09,$09,$08,$07

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
