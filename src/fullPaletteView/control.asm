CHANNEL_COUNT = 3

; global control variables
gControlChannel:
  BYTE 0
gControlValue:
  BYTE 0
gLastTREWQ:
  BYTE $1F
  ; lil buffer to not confuse debugger
  WORD 0

; increment mod will add 1 to A and then if it is equal to B set it back to 0
incrementMod:
  INC A
  CP B
  JR Z, .setToZero
  RET
.setToZero
  XOR A
  RET

; decrement mod will subtract 1 from A and then if it is less than to 0 set it
; to B-1
decrementMod:
  DEC A
  JP M, .setToBMinus1
  RET
.setToBMinus1
  LD A, B
  DEC A
  RET

controlTick:
  LD A, (gLastTREWQ)
  LD D, A
  LD BC, $FBFE ; read TREWQ
  IN A, (C)
  LD (gLastTREWQ), A
  CP D
  JR NZ, .changeHandler
  RET
.changeHandler
  ; we are here because TREWQ changed
  LD E, A
  ; check Q
  BIT 0, D ; was it down before?
  JR Z, .checkW ; if it was down, we are done
  BIT 0, E ; is it down now?
  JR NZ, .checkW ; if it isn't down now, we are done
  ; Q has gone down, decrement control value mod CHANNEL_SIZE
  LD A, (gControlValue)
  LD B, CHANNEL_SIZE
  CALL decrementMod
  LD (gControlValue), A
.checkW
  BIT 1, D
  JR Z, .checkE
  BIT 1, E
  JR NZ, .checkE
  ; W has gone down, increment control value mod CHANNEL_SIZE
  LD A, (gControlValue)
  LD B, CHANNEL_SIZE
  CALL incrementMod
  LD (gControlValue), A
.checkE
  BIT 2, D
  JR Z, .checkR
  BIT 2, E
  JR NZ, .checkR
  ; E has gone down, decrement channel mod CHANNEL_COUNT
  LD A, (gControlChannel)
  LD B, CHANNEL_COUNT
  CALL decrementMod
  LD (gControlChannel), A
.checkR
  BIT 3, D
  JR Z, .done
  BIT 3, E
  JR NZ, .done
  ; E has gone down, increment channel mod CHANNEL_COUNT
  LD A, (gControlChannel)
  LD B, CHANNEL_COUNT
  CALL incrementMod
  LD (gControlChannel), A
.done
  RET
