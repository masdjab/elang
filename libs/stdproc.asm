; written by Heryudi Praja

NO_MORE                   EQU 0ffffh
FAILED                    EQU 0ffffh

CLS_ID_NULL               EQU 0
CLS_ID_FALSE              EQU 2
CLS_ID_TRUE               EQU 4
CLS_ID_OBJECT             EQU 6
CLS_ID_ENUMERATOR         EQU 8
CLS_ID_ARRAY              EQU 10
CLS_ID_STRING             EQU 12

METHOD_ID_INITIALIZE      EQU 1
METHOD_ID_IS_NULL         EQU 2
METHOD_ID_TO_STRING       EQU 3
METHOD_ID_GET_BYTE_AT     EQU 4
METHOD_ID_SET_BYTE_AT     EQU 5
METHOD_ID_GET_WORD_AT     EQU 6
METHOD_ID_SET_WORD_AT     EQU 7

FIRST_BLOCK               EQU 0


mem_block_init:
  ; input: offset, size; output: none
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
  mov ax, NO_MORE
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
  ; input: size; output ax: address
  push bp
  mov bp, sp
  push bx
  mov bx, [FIRST_BLOCK]
_mem_find_free_block_check_current_block:
  mov ax, [bx]
  test ax, ax
  jnz _mem_find_free_block_block_checked
  mov ax, [bx + 2]
  cmp ax, [bp + 4]
  jc _mem_find_free_block_block_checked
  mov ax, bx
  jmp _mem_find_free_block_done
_mem_find_free_block_block_checked:
  mov bx, [bx + 6]
  cmp bx, NO_MORE
  jnz _mem_find_free_block_check_current_block
  mov ax, bx
_mem_find_free_block_done:
  pop bx
  pop bp
  ret 2
  
  
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
  jc _mem_split_block_done
  sub ax, 8
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
  mov ax, si
  mov si, [si + 6]
  cmp si, NO_MORE
  jz _mem_split_block_done
  mov [si + 4], ax
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
  mov ax, [bx]
  test ax, ax
  jnz _mem_merge_free_block_done
_mem_merge_free_block_find_head:
  mov si, [bx + 4]
  cmp si, NO_MORE
  jz _mem_merge_free_block_do_merge
  mov ax, [si]
  test ax, ax
  jnz _mem_merge_free_block_do_merge
  mov bx, si
  jmp _mem_merge_free_block_find_head
_mem_merge_free_block_do_merge:
  mov si, [bx + 6]
  cmp si, NO_MORE
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
  mov si, ax
  mov [si + 4], bx
  jmp _mem_merge_free_block_do_merge
_mem_merge_free_block_done:
  pop si
  pop bx
  pop ax
  pop bp
  ret 2
  
  
mem_alloc:
  ; input: size; output: ax=address
  push bp
  mov bp, sp
  push bx
  mov ax, [bp + 4]
  test ax, 1
  jz _mem_alloc_size_aligned
  inc ax
  mov [bp + 4], ax
_mem_alloc_size_aligned:
  push ax
  call mem_find_free_block
  cmp ax, NO_MORE
  jz _mem_alloc_done
  mov bx, ax
  mov ax, [bp + 4]
  push ax
  push bx
  call mem_split_block
  mov ax, 1
  mov [bx], ax
  mov ax, bx
_mem_alloc_done:
  pop bx
  pop bp
  ret 2
  
  
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
  cmp ax, NO_MORE
  jz _mem_get_data_offset_done
  add ax, 8
_mem_get_data_offset_done:
  pop bp
  ret 2
  
  
mem_get_container_block:
  ; input object; output: ax
  push bp
  mov bp, sp
  mov ax, [bp + 4]
  sub ax, 8
  pop bp
  ret 2
  
  
mem_copy:
  ; input: source, dest, length
  push bp
  mov bp, sp
  push es
  push ax
  push cx
  push si
  push di
  push ds
  pop es
  mov si, [bp + 4]
  mov di, [bp + 6]
  mov cx, [bp + 8]
  test cx, cx
  jz _mem_copy_done
  cld
  cmp si, di
  jz _mem_copy_done
  jnc _mem_copy_start
  std
  mov ax, cx
  dec ax
  add si, ax
  add di, ax
_mem_copy_start:
  lodsb
  stosb
  loop _mem_copy_start
_mem_copy_done:
  pop di
  pop si
  pop cx
  pop ax
  pop es
  pop bp
  ret 6
  
  
mem_resize:
  ; input: target_block, new_size; output: ax
  push bp
  mov bp, sp
  push cx
  push bx
  mov ax, [bp + 6]
  test ax, 1
  jz _mem_resize_new_size_aligned
  inc ax
  mov [bp + 6], ax
_mem_resize_new_size_aligned:
  mov bx, [bp + 4]
  mov ax, [bx + 2]
  cmp ax, [bp + 6]
  jz _mem_resize_done
  jc _mem_resize_expand
_mem_resize_shrink:
  mov ax, [bp + 6]
  push ax
  mov ax, [bp + 4]
  push ax
  call mem_split_block
  mov ax, [bp + 4]
  jmp _mem_resize_done
_mem_resize_expand:
  mov ax, [bp + 6]
  push ax
  call mem_alloc
  cmp ax, NO_MORE
  jz _mem_resize_done
  push ax
  mov cx, [bx + 2]
  push cx
  push ax
  call mem_get_data_offset
  push ax
  push bx
  call mem_get_data_offset
  push ax
  call mem_copy
  mov ax, [bp + 4]
  push ax
  call mem_dealloc
  pop ax
_mem_resize_done:
  pop bx
  pop cx
  pop bp
  ret 4
  
  
alloc_object:
  ; input: class id, instance variable count
  push bp
  mov bp, sp
  push bx
  mov ax, [bp + 6]
  add ax, 1
  shl ax, 1
  push ax
  call mem_alloc
  cmp ax, NO_MORE
  jz _alloc_object_done
  push ax
  call mem_get_data_offset
  push ax
  mov bx, ax
  mov ax, [bp + 4]
  mov [bx], ax
  pop ax
_alloc_object_done:
  pop bx
  pop bp
  ret 4
  
  
create_str:
  ; input: length; output: ax=str object or zero if fail
  push bp
  mov bp, sp
  push si
  mov ax, [bp + 4]
  push ax
  call mem_alloc
  cmp ax, NO_MORE
  jnz _create_str_alloc_success
  mov ax, CLS_ID_NULL
  jmp _create_str_failed
_create_str_alloc_success:
  push ax
  call mem_get_data_offset
  mov si, ax
  mov ax, 2                 ; instance_variable count
  push ax
  mov ax, CLS_ID_STRING     ; class_id
  push ax
  call alloc_object
  cmp ax, NO_MORE
  jz _create_str_failed
  xchg si, ax
  mov [si + 4], ax
  mov ax, [bp + 4]
  mov [si + 2], ax
  mov ax, si
_create_str_failed:
  pop si
  pop bp
  ret 2
  
  
load_str:
  ; input: offset, length; output: ax
  ; string structure:
  ; - class id
  ; - string length
  ; - buffer location
  push bp
  mov bp, sp
  push si
  mov ax, [bp + 6]
  push ax
  call create_str
  cmp ax, CLS_ID_NULL
  jz _load_str_failed
  mov si, ax
  mov ax, [bp + 6]
  push ax
  mov ax, [si + 4]
  push ax
  mov ax, [bp + 4]
  push ax
  call mem_copy
  mov ax, si
_load_str_failed:
  pop si
  pop bp
  ret 4
  
  
str_length:
  ; input: str; output: ax
  push bp
  mov bp, sp
  push bx
  mov bx, [bp + 4]
  mov ax, [bx + 2]
  pop bx
  pop bp
  ret 2
  
str_copy:
  ; input str; output: ax
  ; create a copy of existing string
  push bp
  mov bp, sp
  push si
  push di
  mov si, [bp + 4]
  mov ax, [si + 2]
  push ax
  call create_str
  cmp ax, CLS_ID_NULL
  jz _str_copy_failed
  mov di, ax
  mov ax, [si + 2]
  push ax
  mov ax, [di + 4]
  push ax
  mov ax, [si + 4]
  push ax
  call mem_copy
  mov ax, di
_str_copy_failed:
  pop di
  pop si
  pop bp
  ret 2
  
  
str_concat:
  ; input: str1, str2; output: ax=new str or zero if fail
  push bp
  mov bp, sp
  push cx
  push bx
  push si
  push di
  mov si, [bp + 4]
  mov di, [bp + 6]
  mov cx, [si + 2]
  add cx, [di + 2]
  push cx
  call create_str
  cmp ax, CLS_ID_NULL
  jz _str_concat_failed
  mov bx, ax
  mov ax, [si + 2]
  push ax
  mov ax, [bx + 4]
  push ax
  mov ax, [si + 4]
  push ax
  call mem_copy
  mov ax, [di + 2]
  push ax
  mov ax, [bx + 4]
  add ax, [si + 2]
  push ax
  mov ax, [di + 4]
  push ax
  call mem_copy
  mov ax, bx
_str_concat_failed:
  pop di
  pop si
  pop bx
  pop cx
  pop bp
  ret 4
  
  
str_substr:
  ; input: str, offset, size; output: ax
  push bp
  mov bp, sp
  push si
  push di
  mov ax, [bp + 8]
  push ax
  call create_str
  cmp ax, CLS_ID_NULL
  jz _str_substr_failed
  mov di, ax
  mov si, [bp + 4]
  mov ax, [bp + 8]
  push ax
  mov ax, [di + 4]
  push ax
  mov ax, [si + 4]
  add ax, [bp + 6]
  push ax
  call mem_copy
  mov ax, di
_str_substr_failed:
  pop di
  pop si
  pop bp
  ret 6
  
  
str_lcase:
  ; input: str; output: ax
  push bp
  mov bp, sp
  push cx
  push bx
  push si
  mov ax, [bp + 4]
  push ax
  call str_copy
  cmp ax, CLS_ID_NULL
  jz _str_lcase_done
  mov bx, ax
  mov cx, [bx +  2]
  test cx, cx
  jz _str_lcase_processed
  mov si, [bx + 4]
_str_lcase_loop:
  mov al, [si]
  cmp al, 41h
  jc _str_lcase_skip_char
  cmp al, 5ah
  jg _str_lcase_skip_char
  add al, 20h
  mov [si], al
_str_lcase_skip_char:
  inc si
  loop _str_lcase_loop
_str_lcase_processed:
  mov ax, bx
_str_lcase_done:
  pop si
  pop bx
  pop cx
  pop bp
  ret 2
  
  
str_ucase:
  ; input: str; output: ax
  push bp
  mov bp, sp
  push cx
  push bx
  push si
  mov ax, [bp + 4]
  push ax
  call str_copy
  cmp ax, CLS_ID_NULL
  jz _str_ucase_done
  mov bx, ax
  mov cx, [bx +  2]
  test cx, cx
  jz _str_ucase_processsed
  mov si, [bx + 4]
_str_ucase_loop:
  mov al, [si]
  cmp al, 61h
  jc _str_ucase_skip_char
  cmp al, 7ah
  jg _str_ucase_skip_char
  sub al, 20h
  mov [si], al
_str_ucase_skip_char:
  inc si
  loop _str_ucase_loop
_str_ucase_processsed:
  mov ax, bx
_str_ucase_done:
  pop si
  pop bx
  pop cx
  pop bp
  ret 2
  
  
_cbw:
  ; input: value; output: ax
  push bp
  mov bp, sp
  mov ax, [bp + 4]
  cbw
  pop bp
  ret 2
  
  
_cwb:
  ; input: value; output: ax
  push bp
  mov bp, sp
  mov ax, [bp + 4]
  xor ah, ah
  pop bp
  ret 2
  
  
_get_byte_at:
  ; input: offset, index; output: al
  push bp
  mov bp, sp
  push si
  mov si, [bp + 4]
  add si, [bp + 6]
  mov al, [si]
  pop si
  pop bp
  ret 4
  
  
_set_byte_at:
  ; input: offset, index, value
  push bp
  mov bp, sp
  push ax
  push si
  mov si, [bp + 4]
  add si, [bp + 6]
  mov ax, [bp + 8]
  mov [si], al
  pop si
  pop ax
  pop bp
  ret 6
  
  
_get_word_at:
  ; input: offset, index; output: ax
  push bp
  mov bp, sp
  push si
  mov si, [bp + 4]
  add si, [bp + 6]
  mov ax, [si]
  pop si
  pop bp
  ret 4
  
  
_set_word_at:
  ; input: offset, index, value
  push bp
  mov bp, sp
  push ax
  push si
  mov si, [bp + 4]
  add si, [bp + 6]
  mov ax, [bp + 8]
  mov [si], ax
  pop si
  pop ax
  pop bp
  ret 6
  
  
_int_pack:
  ; input: value; output: ax
  push bp
  mov bp, sp
  shl ax, 1
  or ax, 1
  pop bp
  ret 2
  
  
_int_unpack:
  ; input: value; output: ax
  push bp
  mov bp, sp
  shr ax, 1
  test ax, 4000h
  jz _int_unpack_done
  or ax, 8000h
_int_unpack_done:
  pop bp
  ret 2
  
  
_int_add:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  push ax
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  push ax
  call _int_unpack
  add ax, cx
  push ax
  call _int_pack
  pop cx
  pop bp
  ret 4
  
  
_int_subtract:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  push ax
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  push ax
  call _int_unpack
  sub ax, cx
  push ax
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
  push ax
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  push ax
  call _int_unpack
  imul cx
  push ax
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
  push ax
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  push ax
  call _int_unpack
  idiv cx
  push ax
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
  push ax
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  push ax
  call _int_unpack
  and ax, cx
  push ax
  call _int_pack
  pop cx
  pop bp
  ret 4
  
  
_int_or:
  push bp
  mov bp, sp
  push cx
  mov ax, [bp + 6]
  push ax
  call _int_unpack
  mov cx, ax
  mov ax, [bp + 4]
  push ax
  call _int_unpack
  or ax, cx
  push ax
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
  ; input: al = character code
  ; config: int = 10, ah = 14, bh = page number (text mode), bl = foreground pixel (graphic mode)
  push ax
  push bx
  mov ah, 14
  xor bx, bx
  int 10h
  pop bx
  pop ax
  ret
  
  
_putline:
  push ax
  push bx
  mov al, 13
  call _putchr
  mov al, 10
  call _putchr
  pop bx
  pop ax
  ret
  
  
_putstr:
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
  jz _putstr_done
  cld
  mov ah, 14
  xor bx, bx
_putstr_repeat:
  lodsb
  int 10h
  loop _putstr_repeat
_putstr_done:
  pop si
  pop bx
  pop cx
  pop ax
  pop bp
  ret 4
  
  
_print:
  ; input: str object
  push bp
  mov bp, sp
  push ax
  push bx
  mov bx, [bp + 4]
  mov ax, [bx + 2]    ; length
  push ax
  mov ax, [bx + 4]    ; buffer location
  push ax
  call _putstr
  pop bx
  pop ax
  pop bp
  ret 2
  
  
_puts:
  ; input: str object
  push bp
  mov bp, sp
  push ax
  mov ax, [bp + 4]
  push ax
  call _print
  call _putline
  pop ax
  pop bp
  ret 2
  
_getch:
  ; input: none; output: ax
  push bp
  mov bp, sp
  mov ah, 8
  int 21h
  cbw
  push ax
  call _int_pack
  pop bp
  ret 2
