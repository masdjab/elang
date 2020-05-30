_putchr:
  ; input: al = character code
  ; config: int = 10, ah = 14, bh = page number (text mode), bl = foreground pixel (graphic mode)
  push r_ax
  push r_bx
  mov ah, 14
  xor bx, bx
  int 10h
  pop r_bx
  pop r_ax
  ret
  
  
_putline:
  push r_ax
  push r_bx
  mov al, 13
  call _putchr
  mov al, 10
  call _putchr
  pop r_bx
  pop r_ax
  ret
  
  
_putstr:
  ; input: offset, length
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_cx
  push r_bx
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  mov r_cx, [r_bp + ARGUMENT2]
  test r_cx, r_cx
  jz _putstr_done
  cmp r_cx, 2000
  jc _putstr_char_limited
  mov r_cx, 2000
_putstr_char_limited:
  cld
  mov ah, 14
  xor r_bx, r_bx
_putstr_repeat:
  lodsb
  int 10h
  loop _putstr_repeat
_putstr_done:
  pop r_si
  pop r_bx
  pop r_cx
  pop r_ax
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
_print:
  ; input: str object
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_bx
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx + ATTR_STR_LENGTH]        ; length
  push r_ax
  mov r_ax, [r_bx + ATTR_OBJ_DATA_OFFSET]   ; buffer location
  push r_ax
  call _putstr
  pop r_bx
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
puts:
  ; input: str object
  push r_bp
  mov r_bp, r_sp
  push r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call _print
  call _putline
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
exit_process:
  ret
