org 100h

jmp main
dos_print_dts:
  push bp
  mov bp, sp
  push ax
  push dx
  mov dx, [bp + 4]
  mov ah, 9
  int 21h
  pop dx
  pop ax
  pop bp
  ret 2
  
dos_wait_key:
  push ax
  mov ah, 8
  int 21h
  pop ax
  ret
  
  
message:    db 'Hello world...$'
  
main:
  mov ax, message
  push ax
  call dos_print_dts
  call dos_wait_key
  int 20h
  