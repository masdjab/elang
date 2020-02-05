; written by Heryudi Praja

FAILED                    EQU 0ffffh

mem_block_init:
  ; input: offset, size, output: ax = address of first block
  push bp
  mov bp, sp
  push ax
  push bx
  mov bx, [bp + 4]
  mov ax, [bp + 6]
  cmp ax, 10
  jc _mem_block_init_done
  sub ax, 8
  mov [bx + 2], ax      ; data size
  mov ax, FAILED
  mov [bx + 4], ax      ; prev block
  mov [bx + 6], ax      ; next block
  xor ax, ax
  mov [bx], ax          ; flag
_mem_block_init_done:
  pop bx
  pop ax
  pop bp
  ret 4
  
  
mem_find_free_block:
  ; input: first block, size; output ax: address
  push bp
  mov bp, sp
  push bx
  mov bx, [bp + 4]
_mem_find_free_block_check_current_block:
  mov ax, [bx]
  test ax, ax
  jnz _mem_find_free_block_block_checked
  mov ax, [bx + 2]
  cmp ax, [bp + 6]
  jc _mem_find_free_block_block_checked
  mov ax, bx
  jmp _mem_find_free_block_done
_mem_find_free_block_block_checked:
  mov bx, [bx + 6]
  cmp bx, FAILED
  jnz _mem_find_free_block_check_current_block
  mov ax, bx
_mem_find_free_block_done:
  pop bx
  pop bp
  ret 4
  
  
mem_split_block:
  ; input: block, size
  push bp
  mov bp, sp
  push ax
  push bx
  push si
  mov bx, [bp + 4]
  mov ax, [bx + 2]
  sub ax, [bp + 6]
  sub ax, 10
  jc _mem_split_block_done
  mov ax, [bp + 6]
  add ax, 8
  add ax, bx
  mov si, ax
  xor ax, ax
  mov [si], ax
  mov ax, [bx + 2]
  sub ax, [bp + 6]
  sub ax, 8
  mov [si + 2], ax
  mov [si + 4], bx
  mov ax, [bx + 6]
  mov [si + 6], ax
  mov ax, [bp + 6]
  mov [bx + 2], ax
  mov [bx + 6], si
_mem_split_block_done:
  pop si
  pop bx
  pop ax
  pop bp
  ret 4
  
  
mem_merge_free_block:
  ; input: block
  push bp
  mov bp, sp
  push ax
  push bx
  push si
  mov bx, [bp + 4]
  xor ax, ax
  cmp ax, [bx]
  jnz _mem_merge_free_block_done
_mem_merge_free_block_find_head:
  mov si, [bx + 4]
  cmp si, FAILED
  jz _mem_merge_free_block_do_merge
  mov ax, [si]
  test ax, ax
  jnz _mem_merge_free_block_do_merge
  mov bx, si
  jmp _mem_merge_free_block_find_head
_mem_merge_free_block_do_merge:
  mov si, [bx + 6]
  cmp si, FAILED
  jz _mem_merge_free_block_done
  mov ax, [si]
  test ax, ax
  jnz _mem_merge_free_block_done
  mov ax, [bx + 2]
  add ax, [si + 2]
  add ax, 8
  mov [bx + 2], ax
  mov ax, [si + 6]
  mov [bx + 6], ax
  mov bx, si
  jmp _mem_merge_free_block_do_merge
_mem_merge_free_block_done:
  pop si
  pop bx
  pop ax
  pop bp
  ret 2
  
  
mem_alloc:
  ; input: first_block, size; output: ax=address
  push bp
  mov bp, sp
  push bx
  mov ax, [bp + 6]
  push ax
  mov ax, [bp + 4]
  push ax
  call mem_find_free_block
  cmp ax, FAILED
  jz _mem_alloc_done
  mov bx, ax
  mov ax, [bp + 6]
  push ax
  push bx
  call mem_split_block
  mov ax, 1
  mov [bx], ax
  mov ax, bx
_mem_alloc_done:
  pop bx
  pop bp
  ret 4
  
  
mem_dealloc:
  ; input: block
  push bp
  mov bp, sp
  push ax
  push bx
  mov bx, [bp + 4]
  mov ax, [bx]
  test ax, ax
  jz _mem_dealloc_done
  xor ax, ax
  mov [bx], ax
  push bx
  call mem_merge_free_block
_mem_dealloc_done:
  pop bx
  pop ax
  pop bp
  ret 2
  
  
mem_get_data_offset:
  ; input: block; output: ax
  push bp
  mov bp, sp
  mov ax, [bp + 4]
  cmp ax, FAILED
  jz _mem_get_data_offset_done
  add ax, 8
_mem_get_data_offset_done:
  pop bp
  ret 2
  
  
alloc_object:
  ; input: first_block, class id, instance variable count
  push bp
  mov bp, sp
  push bx
  mov ax, [bp + 8]
  add ax, 1
  shl ax, 1
  push ax
  mov ax, [bp + 4]
  push ax
  call mem_alloc
  cmp ax, FAILED
  jz _alloc_object_done
  push ax
  call mem_get_data_offset
  push ax
  mov bx, ax
  mov ax, [bp + 6]
  mov [bx], ax
  pop ax
_alloc_object_done:
  pop bx
  pop bp
  ret 6
  
  
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
  add ax, 1
  shl ax, 1
  add si, ax
  mov ax, [si]
  pop si
  pop bp
  ret 4
  
  
_set_obj_var:
  ; input: object, var-index, value
  push bp
  mov bp, sp
  push ax
  push si
  mov si, [bp + 4]
  mov ax, [bp + 6]
  add ax, 1
  shl ax, 1
  add si, ax
  mov ax, [bp + 8]
  mov [si], ax
  pop si
  pop ax
  pop bp
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
