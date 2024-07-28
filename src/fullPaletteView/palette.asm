; Registers used
;
; $43 Enhanced ULA Control
; Bit Effect
; 7   1 to disable palette index auto-increment, 0 to enable
; 6-4 Selects palette for read or write
;     000 / 100 ULA first / second palette
;     001 / 101 Layer 2 first / second palette
;     010 / 110 Sprites first / second palette
;     011 / 111 Tilemap first / second palette
;
; $40 Palette Index
; Reads / writes palette colour index to be manipulated
;
; $44 Enhanced ULA Palette Extension
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

initPalette:
  NEXTREG $43, %00010000
  NEXTREG $40, 0
  LD B, 0
.loop
  NEXTREG $44, 0
  NEXTREG $44, 0
  INC B
  ; We want to clear all 256 elements of the palette, so wait for B to wrap
  ; around to 0
  JR NZ, .loop
  RET

; The palette is as follows:
; background colour, set to black
; TODO allow toggling black / grey / white etc.
BG_COLOUR = 0
; CONTROL are the colours of the control channel strip. For now, this is set to
; different shades of blue, as blue is the hard coded control colour
; TODO allow changing control channel
; starts with black and goes to full blue
CHANNEL_SIZE = 8
CONTROL_BEGIN = 1
CONTROL_COUNT = CHANNEL_SIZE
; PALETTE are the colours of the palette itself. This is 2d array of changing
; red \ green intensities.
PALETTE_START = CONTROL_BEGIN + CONTROL_COUNT
PALETTE_COUNT = CHANNEL_SIZE * CHANNEL_SIZE

; When setting the palette we keep the first 8 bit palette value to send in B
; and the second in C
; addChannel adds the value in D, in the channel E, to the value in BC.
; channels are:
; Blue = 0
; Green = 1
; Red = 2
setChannel:
  PUSH DE
  XOR A
  CP E
  JR NZ, .notBlue
  ; Handle blue channel
  ; For blue (and the others) channel we put the value into DE in a way that can
  ; be OR'd with BC for the new value
  LD E, 0
  SRL D
  RL E ; RL should rotate the carry flag into D0
  LD A, B
  AND %11111100
  LD B, A
  LD A, C
  AND %11111110
  LD C, A
  JR .orChannel
.notBlue:
  SLA D
  SLA D
  LD A, $01
  CP E
  JR NZ, .notBlueOrGreen
  ; Handle green channel
  LD A, B
  AND %11100011
  LD B, A
  LD E, 0
  JR .orChannel
.notBlueOrGreen
  ; Handle red channel
  SLA D
  SLA D
  SLA D
  LD A, B
  AND %00011111
  LD B, A
  LD E, 0
.orChannel
  LD A, B
  OR D
  LD B, A
  LD A, C
  OR E
  LD C, A
  POP DE
  RET

updatePalette:
  NEXTREG $40, 0
  ; For now, set two colours, black and blue
  ; First black: first 0, second 0
  LD A, 0
  NEXTREG $44, A
  LD A, 0
  NEXTREG $44, A

  ; Now do 8 iterations of the control channel
  ; First clear the control value and set the channel / value to call setChannel
  LD BC, 0
  LD DE, 0 ; TODO load channel (E) from a global variable!
.debug
  ; JR .debug
.controlloop
  CALL setChannel
  LD A, B
  NEXTREG $44, A
  LD A, C
  NEXTREG $44, A
  INC D
  LD A, CONTROL_COUNT
  CP D
  JR NZ, .controlloop
  ; Now do 8 x 8 iterations of the palette
  LD BC, 0
  ; TODO set control channel value from a global variable
  ; start with DE being value 0, green channel. We set the green channel in
  ; the outer loop
  LD DE, $01
.paletteouterloop
  CALL setChannel
  PUSH DE
  ; now set DE to value 0, red channel. And set the red channel and the
  ; set the palette index to the current colour in the inner loop
  LD DE, $02
.paletteinnerloop
  CALL setChannel
  LD A, B
  NEXTREG $44, A
  LD A, C
  NEXTREG $44, A
  INC D
  LD A, CONTROL_COUNT
  CP D
  JR NZ, .paletteinnerloop
  POP DE
  INC D
  CP D
  JR NZ, .paletteouterloop
  RET
