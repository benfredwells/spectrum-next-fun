GRID_SIZE = 32

; Call with C holding the x offset (where 1 offset == 16 pixels)
; and B holding the Y offset (where 1 offset == 32 pixels)
; and D holding the fg colour
; and E holding the border colour
; BC, DE will be restored upon return
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
.fgcolour
  BYTE 0
.border
  BYTE 0
.start
  PUSH BC
  PUSH DE
  LD HL, 0
  LD (.startx), HL
  LD (.gridx), HL
  LD (.squareindex), HL
  LD A, D
  LD (.fgcolour), A
  LD A, E
  LD (.border), A
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
  ; first setup E by adding gridy to starty
  LD A, (.gridy)
  LD B, A
  LD A, (.starty)
  ADD A, B
  LD E, A
  ; then setup D by adding gridx to startx and also account for the slot offset
  LD A, (.gridx)
  LD C, A
  LD A, (.startx)
  ADD A, C
  AND %00011111
  OR %11000000
  LD D, A
  ; now figure out whether we need to draw or not and the colour to draw
  LD HL, square
  LD BC, (.squareindex)
  INC BC
  LD (.squareindex), BC
  ADD HL, BC
  LD A, (HL)
  ; ok, now we have the value from the bitmap for this pixel. if it is 0, we can
  ; skip drawing
  OR A
  JR Z, .donedrawing
  ; so we have a pixel now. Load the colour to draw
  ; TODO make this a parameters
  LD B, A
  LD A, 2 ; test border
  CP B
  JR Z, .drawBorder
  LD A, (.fgcolour)
  LD (DE), A
  JR .donedrawing
.drawBorder
  LD A, (.border)
  LD (DE), A
.donedrawing:
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
  POP DE
  POP BC
  RET

; Call with C holding the x offset (where 1 offset == 16 pixels)
; and D holding the fg colour to start. This will increment for each square
;     E holding the border colour to start. This will increment for each square,
;       unless it is 0 in which case it will stay at 0
; Will draw for all y offsets (0-7)
; Will mess with B
drawColumn:
  LD B, 0
.loop:
  CALL drawSquare.start
  LD A, E
  OR A
  JR Z, .doneIncrementingBorder
  INC E
.doneIncrementingBorder
  INC D
  INC B
  LD A, 8
  SBC A, B
  JR NZ, .loop
  RET

drawScreen:
  LD D, 1
  LD E, BORDER_START
  ; first draw control column at offset 1
  LD C, $01
  CALL drawColumn
  ; then draw 8 palette squares at offset 4, 6 ... 18
  LD C, $04
  LD E, 0
.paletteloop
  CALL drawColumn
  INC C
  INC C
  LD A, 18
  SBC A, C
  JR NZ, .paletteloop
  RET
