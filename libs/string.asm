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
  
  mov ax, [str_com]
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
  
  mov ax, [str_put]
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
  
  mov ax, [str_ing]
  push ax
  call _puts
  
  ; concat com and put
  mov ax, [str_put]
  push ax
  mov ax, [str_com]
  push ax
  call str_concat
  mov [str_merged1], ax
  
  mov ax, [str_merged1]
  push ax
  call _puts
  
  ; append put and ing to com
  mov si, text_com
  mov ax, [si]
  add si, 2
  push ax
  push si
  call load_str
  mov [str_merged2], ax
  
  mov ax, [str_put]
  push ax
  mov ax, [str_merged2]
  push ax
  call str_append
  
  mov ax, [str_ing]
  push ax
  mov ax, [str_merged2]
  push ax
  call str_append
  
  mov ax, [str_merged2]
  push ax
  call _puts
  
  ; computing.lcase
  mov ax, [str_merged2]
  push ax
  call str_lcase
  mov [str_lower], ax
  
  mov ax, [str_lower]
  push ax
  call _puts
  
  ; computing.ucase
  mov ax, [str_lower]
  push ax
  call str_ucase
  mov [str_upper], ax
  
  mov ax, [str_upper]
  push ax
  call _puts
  
  ; computing.substr(3, 5)
  mov ax, 5
  push ax
  mov ax, 3
  push ax
  mov ax, [str_upper]
  push ax
  call str_substr
  mov [str_part], ax
  
  mov ax, [str_part]
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
str_merged1     dw 0
str_merged2     dw 0
str_lower       dw 0
str_upper       dw 0
str_part        dw 0

dynamic_area:
