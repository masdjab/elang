org 100h

jmp main

include 'stdproc.asm'

main:
  mov cx, 100
_main_print_rep:
  mov ax, [m1size]
  push ax
  mov ax, m1text
  push ax
  call _puts
  loop _main_print_rep
  
  mov ah, 8
  int 21h
  int 20h

m1size  dw 15
m1text  db 'Hello world... '
