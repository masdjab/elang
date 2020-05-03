org 100h

mov ax, main
push ax
ret

include '..\proc16.asm'

main:
  mov cx, cs
  mov ax, data_here
  shr ax, 4
  add ax, cx
  mov ds, ax
  mov ss, ax
  
  mov ax, 8000h
  push ax
  mov ax, dynamic_area
  mov [FIRST_BLOCK], ax
  push ax
  call _mem_block_init
  
  mov ax, 16
  push ax
  call _mem_alloc
  mov [block1], ax
  
  mov ax, 16
  push ax
  call _mem_alloc
  mov [block2], ax
  
  mov ax, 16
  push ax
  call _mem_alloc
  mov [block3], ax
  
  mov ax, 0
  push ax
  mov ax, [block1]
  push ax
  call mem_resize
  mov [block1], ax
  
  mov ax, 20
  push ax
  mov ax, [block2]
  push ax
  call mem_resize
  mov [block2], ax
  
  mov ax, 20
  push ax
  mov ax, [block3]
  push ax
  call mem_resize
  mov [block3], ax
  
  int 20h
  
  
virtual
  align 16
  a = $ - $$
end virtual
db a dup 0

data_here:

org 0
reserved1     dw 0
block1        dw 0
block2        dw 0
block3        dw 0

dynamic_area:
