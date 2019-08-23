

org 100h
jmp begin

include 'INCLUDE\LOADALL.INC'

;expression:
;temp$ = chr$(2 * (pjg - 1) + 5)
;temp$ = pjg - 1
;temp$ = 2 * temp$
;temp$ = temp$ + 5
;temp$ = chr$(temp$)

zadd:

zsub:

zmul:

zchr:

begin:
  call _sysinit

  int 20h


_dummyarea: