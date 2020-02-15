org 100h

mov ax, main
push ax
ret

include 'stdproc.asm'

main:
  mov ax, data_here
  shr ax, 4
  mov cx, cs
  add ax, cx
  mov ds, ax
  mov ss, ax
  
  mov ax, 8000h
  push ax
  mov ax, dynamic_area
  push ax
  call mem_block_init
  mov [FIRST_BLOCK], ax
  
  ; create string com
  mov si, text_com
  mov ax, [si]
  add si, 2
  push ax
  push si
  call load_str
  mov [str_com], ax
  push ax
  call _puts
  
  ; create string put
  mov si, text_put
  mov ax, [si]
  add si, 2
  push ax
  push si
  call load_str
  mov [str_put], ax
  push ax
  call _puts
  
  ; create string ing
  mov si, text_ing
  mov ax, [si]
  add si, 2
  push ax
  push si
  call load_str
  mov [str_ing], ax
  push ax
  call _puts
  
  ; concat com and put
  mov ax, [str_put]
  push ax
  mov ax, [str_com]
  push ax
  call str_concat
  push ax
  call _puts
  
  ; append put and ing to com
  mov si, text_com
  mov ax, [si]
  add si, 2
  push ax
  push si
  call load_str
  mov cx, ax
  mov ax, [str_put]
  push ax
  push cx
  call str_append
  mov ax, [str_ing]
  push ax
  push cx
  call str_append
  push cx
  call _puts
  
  ; computing.lcase
  push cx
  call str_lcase
  mov cx, ax
  push ax
  call _puts
  
  ; computing.ucase
  push cx
  call str_ucase
  mov cx, ax
  push ax
  call _puts
  
  ; computing.substr(3, 5)
  mov ax, 5
  push ax
  mov ax, 3
  push ax
  push cx
  call str_substr
  mov bx, ax
  push ax
  call _puts
  
  ; putin.reverse
  mov ax, [bx + 2]
  push ax
  mov ax, [bx + 4]
  push ax
  call mem_reverse
  push bx
  call _puts
  mov ax, bx
  
  ; nitup.reverse
  push ax
  call str_reverse
  push ax
  call _puts
  
  ; int.to_h8
  mov ax, 89h
  push ax
  call _int_to_h8
  push ax
  call _print
  
  ; int.to_h16
  mov ax, 0cdefh
  push ax
  call _int_to_h16
  push ax
  call _puts
  
  ; int.to_s
  mov ax, 0ffffh
  push ax
  call _int_to_s
  push ax
  call _puts
  
  int 20h
  

virtual
  align 16
  a = $ - $$
end virtual
db a dup 0

data_here:

org 0
reserved_1      dw 0
text_com        db 3, 0, 'COM'
text_put        db 3, 0, 'PUT'
text_ing        db 3, 0, 'ING', 0
str_com         dw 0
str_put         dw 0
str_ing         dw 0

dynamic_area:
