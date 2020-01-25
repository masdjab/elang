; written by Heryudi Praja

int_unpack:
  shr ax, 1
  test ax, 4000h
  jz _int_unpack_done
  or ax, 8000h
_int_unpack_done:
  ret
  
int_pack:
  shl ax, 1
  or ax, 1
  ret
  
int_add:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call int_unpack
  add ax, cx
  call int_pack
  pop cx
  pop bp
  ret 4
  
int_subtract:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call int_unpack
  sub ax, cx
  call int_pack
  pop cx
  pop bp
  ret 4
  
int_multiply:
  push bp
  mov bp, sp
  push cx
  push dx
  xor dx, dx
  mov ax, [bp + 6]
  call int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call int_unpack
  imul cx
  call int_pack
  pop dx
  pop cx
  pop bp
  ret 4
  
int_divide:
  push bp
  mov bp, sp
  push cx
  push dx
  xor dx, dx
  mov ax, [bp + 6]
  call int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call int_unpack
  idiv cx
  call int_pack
  pop dx
  pop cx
  pop bp
  ret 4
  
int_and:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call int_unpack
  and ax, cx
  call int_pack
  pop cx
  pop bp
  ret 4
  
int_or:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  call int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  call int_unpack
  or ax, cx
  call int_pack
  pop cx
  pop bp
  ret 4
  
get_obj_var:
  push bp
  mov bp, sp
  push si
  mov si, [bp + 4]
  add si, [bp + 6]
  mov ax, [si]
  pop si
  pop bp
  ret
  
set_obj_var:
  push bp
  mov bp, sp
  push ax
  push si
  mov si, [bp + 4]
  add si, [bp + 6]
  mov ax, [bp + 4]
  mov [si], ax
  pop si
  pop ax
  pop bp
  ret
