org 100h
mov ax, main
push ax
ret

include 'stdproc.asm'

func1:
  mov ax, [bp + 4]
  mov ax, [bp + 6]
  mov ax, [bp + 8]
  mov ax, [bp + 10]
  mov ax, [bp + 12]
  mov ax, [bp + 14]
  mov ax, 6666h
  call _set_result
  ret
  
main:
  mov ax, 22h
  push ax
  mov ax, 21h
  push ax
  mov ax, 11h
  push ax
  mov ax, 2
  push ax
  mov ax, 1
  push ax
  mov ax, func1
  push ax
  call _pass_arguments
  int 20h
