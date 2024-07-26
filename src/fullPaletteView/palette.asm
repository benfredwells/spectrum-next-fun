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

  ; For now, set two colours, black and blue
  ; First black: first 0, second 0
  NEXTREG $40, 0
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
