org 100h

jmp main

include 'stdproc.asm'

main:
  mov ax, 100h
  push ax
  mov ax, dynamic_area
  push ax
  call mem_block_init
  mov [first_block], ax
  
  mov ax, 10h
  push ax
  mov ax, [first_block]
  push ax
  call mem_alloc
  mov [block_1], ax
  
  push ax
  call mem_get_data_offset
  mov si, ax
  mov ax, 1234h
  mov [si], ax
  mov ax, 5678h
  mov [si + 2], ax
  
  mov ax, 20h
  push ax
  mov ax, [first_block]
  push ax
  call mem_alloc
  mov [block_2], ax
  
  mov ax, 10h
  push ax
  mov ax, [first_block]
  push ax
  call mem_alloc
  mov [block_3], ax
  
  mov ax, 10h
  push ax
  mov ax, [first_block]
  push ax
  call mem_alloc
  mov [block_4], ax
  
  mov ax, 10h
  push ax
  mov ax, [first_block]
  push ax
  call mem_alloc
  mov [block_5], ax
  
  mov ax, [block_3]
  push ax
  call mem_dealloc
  
  mov ax, [block_2]
  push ax
  call mem_dealloc
  
  mov ax, [block_4]
  push ax
  call mem_dealloc
  
  mov ax, 40h
  push ax
  mov ax, [first_block]
  push ax
  call mem_alloc
  mov [block_6], ax
  
  int 20h
  
  
org 420h
first_block dw 0
block_1     dw 0
block_2     dw 0
block_3     dw 0
block_4     dw 0
block_5     dw 0
block_6     dw 0

org 430h
dynamic_area:
