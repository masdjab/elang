org 100h

jmp main

include '..\proc16.asm'

main:
_main_print_rep:
  mov ax, string1
  push ax
  call _puts
  
  mov ax, string2
  push ax
  call _puts
  
  mov ah, 8
  int 21h
  int 20h
  
  
m1size    dw 15
m1text    db 'Hello world... '
m2size    dw 15
m2text    db 'Simple text...'

string1   dw 10, 15, m1text
string2   dw 10, 15, m2text
