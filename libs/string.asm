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
  
  ; create string mista
  mov si, text_mista
  mov ax, [si]
  add si, 2
  push ax
  push si
  call load_str
  mov [str_mista], ax
  
  mov ax, [str_mista]
  push ax
  call _puts
  
  ; create string kenly
  mov si, text_kenly
  mov ax, [si]
  add si, 2
  push ax
  push si
  call load_str
  mov [str_kenly], ax
  
  mov ax, [str_kenly]
  push ax
  call _puts
  
  ; merge mista and kenly
  mov ax, [str_kenly]
  push ax
  mov ax, [str_mista]
  push ax
  call str_append
  mov [str_merged], ax
  
  mov ax, [str_merged]
  push ax
  call _puts
  
  ; mistakenly.lcase
  mov ax, [str_merged]
  push ax
  call str_lcase
  mov [str_lower], ax
  
  mov ax, [str_lower]
  push ax
  call _puts
  
  ; mistakenly.ucase
  mov ax, [str_lower]
  push ax
  call str_ucase
  mov [str_upper], ax
  
  mov ax, [str_upper]
  push ax
  call _puts
  
  ; mistakenly.substr(3, 5)
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
text_mista      db 5, 0, 'MISTA'
text_kenly      db 5, 0, 'KENLY'

str_mista       dw 0
str_kenly       dw 0
str_merged      dw 0
str_lower       dw 0
str_upper       dw 0
str_part        dw 0

dynamic_area:
