org 100h
jmp main

include 'stdlib.asm'

main:
  mov ax, 10
  call make_int
  mov [intv1], ax
  mov ax, 2
  call make_int
  mov [intv2], ax
  
  mov ax, [intv2]
  push ax
  mov ax, 1
  push ax
  mov ax, METH_ID_INT_ADD
  push ax
  mov ax, [intv1]
  push ax
  call invoke_method
  mov [intv3], ax
  int 20h
  
intv1     dw 0
intv2     dw 0
intv3     dw 0
eoc       db '*** End of Code ***'
