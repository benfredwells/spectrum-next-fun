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
