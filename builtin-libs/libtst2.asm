org 100h

jmp main
push_hello_world:
  pop bx
  push hello_world
  push bx
  ret
  
push_press_any_key:
  pop bx
  push press_any_key
  push bx
  ret
  
dos_print_dts:
  pop bx
  pop dx
  push bx
  mov ah, 9
  int 21h
  ret
  
dos_wait_key:
  push ax
  mov ah, 8
  int 21h
  pop ax
  ret

main:
call push_hello_world
call dos_print_dts
call push_press_any_key
call dos_print_dts
call dos_wait_key
int 20h

hello_world     db 'Hello world...', 13, 10, 24h
press_any_key   db 'Press eny key to exit', 13, 10, 24h
