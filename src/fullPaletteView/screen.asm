GRID_SIZE = 32

BG_COLOUR = 0
FG_COLOUR = 1

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
  ; the current index into the sqauare bitmap
.squareindex
  WORD 0
  ; the initial bank, used as we might need to increment and set again while
  ; drawing
.startbank
  BYTE 0
.start
  PUSH BC
  LD HL, 0
  LD (.startx), HL
  LD (.gridx), HL
  LD (.squareindex), HL
  ; Initialize bank. Due to the way this is called (currently) we can rely on
  ; all columns being in the same bank, so we just need to look at the starting
  ; x offset. Each bank covers 32 columns, which is 2 "offsets".
  LD A, C
  SRL A
  LD D, LAYER2_8K_BANK
  ADD A, D
  LD (.startbank), A
  ; Memory Management Slot 6 Bank $56
  ; Contains the 8K bank address for Slot 6
  NEXTREG $56, A

  ; Find the start offsets
  LD A, C
  AND %00000001
  SLA A
  SLA A
  SLA A
  SLA A
  LD (.startx), A
  LD A, B
  SLA A
  SLA A
  SLA A
  SLA A
  SLA A
  LD (.starty), A
  JR .writeVerticalLine
.checkBank
  ; check if the bank needs to be incremented
  LD A, (.gridx)
  LD B, A
  LD A, (.startx)
  ADD A, B
  AND %00100000
  JR Z, .writeVerticalLine
  ; if the absolute x position was 32 we end up here. Increment bank
  LD A, (.startbank)
  INC A
  NEXTREG $56, A
.writeVerticalLine
.writePixel:
  LD A, (.gridy)
  LD B, A
  LD A, (.starty)
  ADD A, B
  LD E, A
  LD A, (.gridx)
  LD C, A
  ; add the slot offset to have DE point into the screen buffer, and the
  ; start offsets as well
  LD A, (.startx)
  ADD A, C
  AND %00011111
  OR %11000000
  LD D, A
  LD HL, square
  LD BC, (.squareindex)
  INC BC
  LD (.squareindex), BC
  ADD HL, BC
  LD A, (HL)
  LD (DE), A
  LD A, (.gridy)
  INC A
  LD (.gridy), A
  LD B, A
  LD A, GRID_SIZE
  SBC A, B
  ; If we have done square_sizes[column] pixels we're done
  JR NZ, .writePixel
  XOR A
  LD (.gridy), A
  LD A, (.gridx)
  INC A
  LD (.gridx), A
  LD C, A
  LD A, GRID_SIZE
  SBC A, C
  JR NZ, .checkBank
  POP BC
  RET

drawScreen:
  LD B, 0
.rowloop
  ; first draw control square at offset 1
  LD C, $01
  CALL drawSquare.start
  ; then draw 8 palette squares at offset 4, 6 ... 18
  LD C, $04
.paletteloop
  CALL drawSquare.start
  INC C
  INC C
  LD A, 18
  SBC A, C
  JR NZ, .paletteloop
  INC B
  ; do all that 8 times
  LD A, 8
  SBC A, B
  JR NZ, .rowloop
  RET
