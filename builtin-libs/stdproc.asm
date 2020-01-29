; written by Heryudi Praja

_cbw:
  push bp
  mov bp, sp
  mov ax, [bp + 4]
  cbw
  pop bp
  ret 2
  
_int_pack:
  shl ax, 1
  or ax, 1
  ret
  
_int_unpack:
  shr ax, 1
  test ax, 4000h
  jz _int_unpack_done
  or ax, 8000h
_int_unpack_done:
  ret
  
_int_add:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call _int_unpack
  add ax, cx
  call _int_pack
  pop cx
  pop bp
  ret 4
  
_int_subtract:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call _int_unpack
  sub ax, cx
  call _int_pack
  pop cx
  pop bp
  ret 4
  
_int_multiply:
  push bp
  mov bp, sp
  push cx
  push dx
  xor dx, dx
  mov ax, [bp + 6]
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call _int_unpack
  imul cx
  call _int_pack
  pop dx
  pop cx
  pop bp
  ret 4
  
_int_divide:
  push bp
  mov bp, sp
  push cx
  push dx
  xor dx, dx
  mov ax, [bp + 6]
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call _int_unpack
  idiv cx
  call _int_pack
  pop dx
  pop cx
  pop bp
  ret 4
  
_int_and:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call _int_unpack
  and ax, cx
  call _int_pack
  pop cx
  pop bp
  ret 4
  
_int_or:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call _int_unpack
  or ax, cx
  call _int_pack
  pop cx
  pop bp
  ret 4
  
_get_obj_var:
  ; input: object, var-index
  push bp
  mov bp, sp
  push si
  mov si, [bp + 4]
  mov ax, [bp + 6]
  shl ax, 1
  add si, ax
  mov ax, [si]
  pop si
  pop bp
  ret
  
_set_obj_var:
  ; input: object, var-index, value
  push bp
  mov bp, sp
  push ax
  push si
  mov si, [bp + 4]
  add ax, [bp + 6]
  shl ax, 1
  add si, ax
  mov ax, [bp + 8]
  mov [si], ax
  pop si
  pop ax
  pop bp
  ret
  
_send_to_object:
  ; dummy function
  ; input: object, method id, argument
  ret 6
  
_putchr:
  ; input: int = 10, ah = 14, al = character code, bh = page number (text mode), bl = foreground pixel (graphic mode)
  push ax
  push bx
  mov ah, 14
  xor bx, bx
  int 10h
  pop bx
  pop ax
  ret
  
_print:
  ; input: offset, length
  push bp
  mov bp, sp
  push ax
  push cx
  push bx
  push si
  mov si, [bp + 4]
  mov cx, [bp + 6]
  test cx, cx
  jz _puts_done
  cld
  mov ah, 14
  xor bx, bx
_puts_repeat:
  lodsb
  int 10h
  loop _puts_repeat
_puts_done:
  pop si
  pop bx
  pop cx
  pop ax
  pop bp
  ret 4
  
_puts:
  ; input: str object
  ; string structure:
  ; - class id
  ; - string length
  ; - buffer location
  push bp
  mov bp, sp
  mov bx, [bp + 4]
  mov ax, [bx + 2]    ; length
  push ax
  mov ax, [bx + 4]    ; buffer location
  push ax
  call _print
  pop bp
  ret 2

_getch:
  mov ah, 8
  int 21h
  cbw
  call _int_pack
  ret
