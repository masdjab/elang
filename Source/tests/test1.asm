org 100h

jmp main
print:
  push bp
  mov bp, sp
  push ax
  push dx
  mov ah, 9
  mov dx, [bp + 4]
  int 21h
  pop dx
  pop ax
  pop bp
  ret 2
  
waitkey:
  push bp
  mov bp, sp
  push ax
  push si
  mov ah, 8
  int 21h
  mov si, [bp + 4]
  mov [si], al
  pop si
  pop ax
  pop bp
  ret 2

main:
  push keycode
  call waitkey
  mov al, [keycode]
  mov [number], al
  push info
  call print
  cmp byte [keycode], 30h
  jnz main
  int 20h

info:       db 'Key '
number:     db 0, ' pressed', 13, 10, '$'
keycode:    dw 0
