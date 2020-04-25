org 100h
jmp main
include '..\stdlib16.asm'
main:
  mov si, test1
  mov di, si
  add di, 2
  mov cx, 16
  push cx
  push di
  push si
  call mem_copy
  
  push cx
  push si
  push di
  call mem_copy
  
  nop
  nop
  nop
  int 20h
  
test1     db '#Hello world...#'
