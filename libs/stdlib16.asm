include 'fasm16.asm'

INT_MIN_MASK1             EQU 8000h
INT_MIN_MASK2             EQU 4000h

macro var [varargs] {dw varargs}

var table
var 7 dup 0

include 'stdproc.asm'
include 'dos.asm'
include 'stdtable.asm'
