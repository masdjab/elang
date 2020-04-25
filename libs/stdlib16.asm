include 'fasm16.asm'

INT_MIN_MASK1             EQU 8000h
INT_MIN_MASK2             EQU 4000h

macro var [varargs] {dd varargs}

var table
var 7 dup 0

include 'proc32.asm'
include 'stdtable.asm'
