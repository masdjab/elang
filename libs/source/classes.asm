METH_ID_OBJ_INIT        EQU 1
METH_ID_OBJ_DESTROY     EQU 2
METH_ID_OBJ_CLASS_ID    EQU 3
METH_ID_OBJ_IS_NIL      EQU 4
METH_ID_OBJ_IS_TYPE_OF  EQU 5
METH_ID_OBJ_TO_S        EQU 6
METH_ID_INT_ADD         EQU 7
METH_ID_INT_SUB         EQU 8
METH_ID_INT_MUL         EQU 9
METH_ID_INT_DIV         EQU 10
METH_ID_INT_AND         EQU 11
METH_ID_INT_OR          EQU 12
METH_ID_INT_XOR         EQU 13
METH_ID_INT_NOT         EQU 14
METH_ID_STRING_NEW      EQU 15
METH_ID_STRING_LENGTH   EQU 16
METH_ID_STRING_ELEMENT  EQU 17
METH_ID_STRING_UCASE    EQU 18
METH_ID_STRING_LCASE    EQU 19
METH_ID_CONSOLE_PUTS    EQU 20
METH_ID_CONSOLE_GETCH   EQU 21

IVO_OBJ_CLASS_ID        EQU 0
IVO_OBJ_LENGTH          EQU 2

CLS_ID_NIL              EQU 0
CLS_ID_FALSE            EQU 2
CLS_ID_TRUE             EQU 3
CLS_ID_STR              EQU 4
CLS_ID_CONSOLE          EQU 5


is_number:
  ; input: ax, output: zf
  test ax, 1
  ret
  
is_nil:
  ; input: ax, output: zf
  cmp ax, 2
  ret
  
is_false:
  ; input: ax, output: zf
  cmp ax, 4
  ret
  
is_true:
  ; input: ax, output: zf
  cmp ax, 6
  ret
  
is_object:
  ; input: ax, output: zf
  cmp ax, 7
  jc _is_object_false
_is_object_true:
  xor ax, ax
  ret
_is_object_false:
  or ax, 1
  ret
  
print:
  ; input: dx: error msg
  mov ah, 9
  int 21h
  ret
  
mem_block_init:
  ; input: offset, size, output: ax = address of first block
  push bp
  mov bp, sp
  push cx
  push dx
  push bx
  mov bx, [bp + 4]
  mov dx, [bp + 6]
  mov cx, [bp + 8]
  xor ax, ax
  mov [bx], ax          ; flag
  mov [bx + 2], cx      ; data size
  mov ax, 0ffffh
  mov [bx + 4], ax      ; prev block
  mov [bx + 6], ax      ; next block
  pop bx
  pop dx
  pop cx
  pop bp
  ret 6
  
mem_find_free_block:
  ; input: first block, size; output ax: address
  push bp
  mov bp, sp
  push bx
  mov bx, [bp + 4]
_mem_find_free_block_check_current_block:
  cmp word [bx], 0
  jnz _mem_find_free_block_block_checked
  mov ax, [bx + 2]
  cmp ax, [bp + 6]
  jc _mem_find_free_block_block_checked
  mov ax, bx
  jmp _mem_find_free_block_done
_mem_find_free_block_block_checked:
  mov bx, [bx + 6]
  cmp bx, 0ffffh
  jz _mem_find_free_block_check_current_block
  mov ax, 0ffffh
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
  mov ax, [bp + 6]
  add ax, 10
  cmp ax, [bx + 2]
  jc _mem_splittable_block_done
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
_mem_splittable_block_done:
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
  cmp si, 0ffffh
  jz _mem_merge_free_block_do_merge
  mov ax, [si]
  test ax, ax
  jz _mem_merge_free_block_do_merge
  mov bx, si
  jmp _mem_merge_free_block_find_head
_mem_merge_free_block_do_merge:
  mov si, [bx + 6]
  cmp si, 0ffffh
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
  cmp ax, 0ffffh
  jz _mem_alloc_done
  mov bx, ax
  mov ax, [bp + 6]
  push ax
  push bx
  call mem_split_block
  xor ax, ax
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
  
  
  
create_object_at:
  ; input: ax: clsid, cx: number_of_instance_variables, bx: address
  mov si, bx
  add si, 2
  mov [si], cx
  cld
  mov ax, CLS_ID_NIL
  repnz
  stosw
  ret
  
create_object:
  ; input: ax: clsid, cx: number_of_instance_variables
  call mem_alloc
  call create_object_at
  ret
  
destroy_object:
  ; input: bx: object
  mov si, bx
  add si, 2
  mov cx, [si]
  dec cx
  jz _destroy_object_dealloc_done
  mov ax, METH_ID_OBJ_DESTROY
_destroy_object_dealloc:
  mov bx, [si]
  call invoke_method
  add si, 2
  loop _destroy_object_dealloc
_destroy_object_dealloc_done:
  call mem_dealloc
  ret
  
; Object
obj_has_no_such_method:
  ret
  
obj_method_not_implemented:
  ret
  
obj_init:
  ret
  
obj_destroy:
  push bp
  mov bp, sp
  mov bx, [bp + 4]
  call destroy_object
  pop bp
  ret 2
  
obj_class_id:
  push bp
  mov bp, sp
  mov bx, [bp + 4]
  mov ax, [bx]
  pop bp
  ret
  
obj_is_nil:
  ret
  
obj_is_type_of:
  ret
  
obj_to_s:
  ret
  
invoke_obj_method:
  mov bp, sp
  mov ax, [bp + 4]
_invoke_obj_method_init:
  cmp ax, METH_ID_OBJ_INIT
  jnz _invoke_obj_method_destroy
  jmp obj_init
_invoke_obj_method_destroy:
  cmp ax, METH_ID_OBJ_DESTROY
  jnz _invoke_obj_method_class_id
  jmp obj_destroy
_invoke_obj_method_class_id:
  cmp ax, METH_ID_OBJ_CLASS_ID
  jnz _invoke_obj_method_is_nil
  jmp obj_class_id
_invoke_obj_method_is_nil:
  cmp ax, METH_ID_OBJ_IS_NIL
  jnz _invoke_obj_method_is_type_of
  jmp obj_is_nil
_invoke_obj_method_is_type_of:
  cmp ax, METH_ID_OBJ_IS_TYPE_OF
  jnz _invoke_obj_method_to_s
  jmp obj_is_type_of
_invoke_obj_method_to_s:
  cmp ax, METH_ID_OBJ_TO_S
  jnz _invoke_obj_method_no_such_method
  jmp obj_to_s
_invoke_obj_method_no_such_method:
  jmp obj_has_no_such_method
  
; Nil
invoke_nil_method:
  ret
  
; True
invoke_true_method:
  ret
  
; False
invoke_false_method:
  ret
  
; Integer
make_int:
  shl ax, 1
  or ax, 1
  ret
  
int_val:
  shr ax, 1
  test ax, 4000h
  jz _int_val_positive
_int_val_negative:
  or ax, 8000h
_int_val_positive:
  ret
  
int_add:
  ; input: self, method, args_count, *args
  mov bp, sp
  mov ax, [bp + 8]
  call int_val
  mov cx, ax
  mov ax, [bp + 2]
  call int_val
  add ax, cx
  call make_int
  ret 4
  
int_sub:
  ; input: self, method, args_count, *args
  mov bp, sp
  mov ax, [bp + 8]
  call int_val
  mov cx, ax
  mov ax, [bp + 2]
  call int_val
  sub ax, cx
  call make_int
  ret 4
  
int_mul:
int_div:
int_and:
int_or:
int_xor:
int_not:
  ret
  
invoke_int_method:
  mov bp, sp
  mov ax, [bp + 4]
_invoke_int_method_add:
  cmp ax, METH_ID_INT_ADD
  jnz _invoke_int_method_sub
  jmp int_add
_invoke_int_method_sub:
  cmp ax, METH_ID_INT_SUB
  jnz _invoke_int_method_mul
  jmp int_sub
_invoke_int_method_mul:
  cmp ax, METH_ID_INT_MUL
  jnz _invoke_int_method_div
  jmp int_mul
_invoke_int_method_div:
  cmp ax, METH_ID_INT_DIV
  jnz _invoke_int_method_and
  jmp int_div
_invoke_int_method_and:
  cmp ax, METH_ID_INT_AND
  jnz _invoke_int_method_or
  jmp int_and
_invoke_int_method_or:
  cmp ax, METH_ID_INT_OR
  jnz _invoke_int_method_xor
  jmp int_or
_invoke_int_method_xor:
  cmp ax, METH_ID_INT_XOR
  jnz _invoke_int_method_not
  jmp int_xor
_invoke_int_method_not:
  cmp ax, METH_ID_INT_NOT
  jnz _invoke_int_method_other
  jmp int_not
_invoke_int_method_other:
  jmp invoke_obj_method
  
; Enumerator
invoke_enumerator_method:
  ret
  
; String
str_new:
str_length:
str_element:
str_ucase:
str_lcase:
  ret
  
invoke_str_method:
  mov bp, sp
  mov ax, [bp + 4]
_invoke_str_method_new:
  cmp ax, METH_ID_STRING_NEW
  jnz _invoke_str_method_length
  jmp str_new
_invoke_str_method_length:
  cmp ax, METH_ID_STRING_LENGTH
  jnz _invoke_str_method_element
  jmp str_length
_invoke_str_method_element:
  cmp ax, METH_ID_STRING_ELEMENT
  jnz _invoke_str_method_ucase
  jmp str_element
_invoke_str_method_ucase:
  cmp ax, METH_ID_STRING_UCASE
  jnz _invoke_str_method_lcase
  jmp str_ucase
_invoke_str_method_lcase:
  cmp ax, METH_ID_STRING_LCASE
  jnz _invoke_str_method_other
  jmp str_lcase
_invoke_str_method_other:
  jmp invoke_obj_method
  
;(todo);Exception
  
; Console
console_puts:
  ; input: string
  ret
  
console_getch:
  ret
  
invoke_console_method:
  mov bp, sp
  mov ax, [bp + 4]
_invoke_console_method_puts:
  cmp ax, METH_ID_CONSOLE_PUTS
  jnz _invoke_console_method_getch
  jmp console_puts
_invoke_console_method_getch:
  cmp ax, METH_ID_CONSOLE_GETCH
  jnz _invoke_console_method_other
  jmp console_getch
_invoke_console_method_other:
  jmp invoke_obj_method
  
invoke_method:
  ; input: object, method_id, args_count, *args
  mov bp, sp
  mov bx, [bp + 2]
_invoke_method_for_nil:
  cmp bx, CLS_ID_NIL
  jnz _invoke_method_for_false
  jmp invoke_nil_method
_invoke_method_for_false:
  cmp bx, CLS_ID_FALSE
  jnz _invoke_method_for_true
  jmp invoke_false_method
_invoke_method_for_true:
  cmp bx, CLS_ID_TRUE
  jnz _invoke_method_for_int
  jmp invoke_true_method
_invoke_method_for_int:
  test dx, 1
  jnz _invoke_method_for_str
  jmp invoke_int_method
_invoke_method_for_str:
  cmp bx, CLS_ID_STR
  jnz _invoke_method_for_console
  jmp invoke_str_method
_invoke_method_for_console:
  cmp bx, CLS_ID_CONSOLE
  jnz _invoke_method_for_obj
  jmp invoke_console_method
_invoke_method_for_obj:
  jmp invoke_obj_method
  
; =====================================================
  
dos_print_dts:
  push bp
  mov bp, sp
  push ax
  push dx
  mov dx, [bp + 4]
  mov ah, 9
  int 21h
  pop dx
  pop ax
  pop bp
  ret 2
  
dos_wait_key:
  push ax
  mov ah, 8
  int 21h
  pop ax
  ret
