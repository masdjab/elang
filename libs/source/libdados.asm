include 'fasm32.asm'

INT_MIN_MASK1             EQU 80000000h
INT_MIN_MASK2             EQU 40000000h

macro var [varargs] {dd varargs}

dw 2
dw table
dw 7 dup 0

include 'stdproc.asm'
include 'dados.asm'
include 'stdtable.asm'
