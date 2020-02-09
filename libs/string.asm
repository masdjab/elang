org 100h
jmp main
include 'stdproc.asm'

main:
  mov ax, 8000h
  push ax
  mov ax, dynamic_area
  push ax
  call mem_block_init
  
  ; create string mista
  mov si, text_mista
  mov ax, [si]
  add si, 2
  push ax
  push si
  mov ax, dynamic_area
  push ax
  call load_str
  mov [str_mista], ax
  
  mov ax, [str_mista]
  push ax
  call _puts
  call _putline
  
  ; create string kenly
  mov si, text_kenly
  mov ax, [si]
  add si, 2
  push ax
  push si
  mov ax, dynamic_area
  push ax
  call load_str
  mov [str_kenly], ax
  
  mov ax, [str_kenly]
  push ax
  call _puts
  call _putline
  
  ; merge mista and kenly
  mov ax, [str_kenly]
  push ax
  mov ax, [str_mista]
  push ax
  mov ax, dynamic_area
  push ax
  call str_append
  mov [str_merged], ax
  
  mov ax, [str_merged]
  push ax
  call _puts
  call _putline
  
  ; mistakenly.lcase
  mov ax, [str_merged]
  push ax
  mov ax, dynamic_area
  push ax
  call str_lcase
  mov [str_lower], ax
  
  mov ax, [str_lower]
  push ax
  call _puts
  call _putline
  
  ; mistakenly.ucase
  mov ax, [str_lower]
  push ax
  mov ax, dynamic_area
  push ax
  call str_ucase
  mov [str_upper], ax
  
  mov ax, [str_upper]
  push ax
  call _puts
  call _putline
  
  ; mistakenly.substr(3, 5)
  mov ax, 5
  push ax
  mov ax, 3
  push ax
  mov ax, [str_upper]
  push ax
  mov ax, dynamic_area
  push ax
  call str_substr
  mov [str_part], ax
  
  mov ax, [str_part]
  push ax
  call _puts
  call _putline
  
  int 20h
  

text_mista      db 5, 0, 'MISTA'
text_kenly      db 5, 0, 'KENLY'

str_mista       dw 0
str_kenly       dw 0
str_merged      dw 0
str_lower       dw 0
str_upper       dw 0
str_part        dw 0

dynamic_area:
