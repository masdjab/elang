; written by Heryudi Praja

NO_MORE                   EQU 0ffffffffh
FAILED                    EQU 0ffffffffh
GARBAGE                   EQU 0ffffffffh
MAX_REF_COUNT             EQU 0fffffffeh
CODE_BASE_ADDRESS         EQU 100h

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

BLOCK_STRUCT_SIZE         EQU 16
ATTR_BLOCK_FLAG           EQU 0
ATTR_BLOCK_SIZE           EQU 4
ATTR_BLOCK_PREV           EQU 8
ATTR_BLOCK_NEXT           EQU 12

ATTR_OBJ_CLASS_ID         EQU 0
ATTR_STR_LENGTH           EQU 4
ATTR_OBJ_DATA_OFFSET      EQU 8

; reserved system data
FIRST_BLOCK               EQU 0
FREE_BLOCK_SIZE           EQU 4
USED_BLOCK_SIZE           EQU 8
GARBAGE_COUNT             EQU 12


_pass_arguments:
  ; input: function, mandatory_count, optional count, arguments
  ; return value should be put at [bp - 4]
  push ebp
  mov ebp, esp
  push eax
  mov eax, _pass_arguments_return
  push eax
  mov eax, [ebp + 8]
  push eax
  ret
_pass_arguments_return:
  push esi
  mov esi, ebp
  mov eax, [ebp + 12]
  add eax, [ebp + 16]
  add eax, 10
  shl eax, 2
  add esi, eax
  mov eax, [ebp + 4]
  xchg ebp, esi
  mov [ebp], eax
  xchg ebp, esi
  mov [ebp + 4], esi
  pop esi
  pop eax
  pop ebp
  pop esp
  ret
  
  
_set_result:
  mov [ebp - 2], eax
  ret
  
  
_mem_block_init:
  ; input: offset, size; output: none
  push ebp
  mov ebp, esp
  push eax
  push ebx
  mov ebx, [ebp + 8]
  mov eax, [ebp + 12]
  cmp eax, BLOCK_STRUCT_SIZE
  jc _mem_block_init_done
  sub eax, BLOCK_STRUCT_SIZE
  mov [FREE_BLOCK_SIZE], eax
  mov [ebx + ATTR_BLOCK_SIZE], eax    ; data size
  mov eax, NO_MORE
  mov [ebx + ATTR_BLOCK_PREV], eax    ; prev block
  mov [ebx + ATTR_BLOCK_NEXT], eax    ; next block
  xor eax, eax
  mov [ebx + ATTR_BLOCK_FLAG], eax    ; flag
_mem_block_init_done:
  xor eax, eax
  mov [USED_BLOCK_SIZE], eax
  mov [GARBAGE_COUNT], eax
  mov [FIRST_BLOCK], ebx
  pop ebx
  pop eax
  pop ebp
  ret 8
  
  
mem_find_free_block:
  ; input: size; output ax: address
  push ebp
  mov ebp, esp
  push ebx
  mov ebx, [FIRST_BLOCK]
_mem_find_free_block_check_current_block:
  mov eax, [ebx + ATTR_BLOCK_FLAG]
  test eax, eax
  jnz _mem_find_free_block_block_checked
  mov eax, [ebx + ATTR_BLOCK_SIZE]
  cmp eax, [ebp + 8]
  jc _mem_find_free_block_block_checked
  mov eax, ebx
  jmp _mem_find_free_block_done
_mem_find_free_block_block_checked:
  mov ebx, [ebx + ATTR_BLOCK_NEXT]
  cmp ebx, NO_MORE
  jnz _mem_find_free_block_check_current_block
  mov eax, ebx
_mem_find_free_block_done:
  pop ebx
  pop ebp
  ret 4
  
  
mem_split_block:
  ; input: block, size
  push ebp
  mov ebp, esp
  push eax
  push ebx
  push esi
  mov ebx, [ebp + 8]
  mov eax, [ebx + ATTR_BLOCK_SIZE]
  sub eax, [ebp + 12]
  jc _mem_split_block_done
  sub eax, BLOCK_STRUCT_SIZE
  jc _mem_split_block_done
  mov eax, [ebp + 12]
  add eax, BLOCK_STRUCT_SIZE
  add eax, ebx
  mov esi, eax
  xor eax, eax
  mov [esi + ATTR_BLOCK_FLAG], eax
  mov eax, [ebx + ATTR_BLOCK_SIZE]
  sub eax, [ebp + 12]
  sub eax, BLOCK_STRUCT_SIZE
  mov [esi + ATTR_BLOCK_SIZE], eax
  mov [esi + ATTR_BLOCK_PREV], ebx
  mov eax, [ebx + ATTR_BLOCK_NEXT]
  mov [esi + ATTR_BLOCK_NEXT], eax
  mov eax, [ebp + 12]
  mov [ebx + ATTR_BLOCK_SIZE], eax
  mov [ebx + ATTR_BLOCK_NEXT], esi
  mov eax, [FREE_BLOCK_SIZE]
  sub eax, BLOCK_STRUCT_SIZE
  mov [FREE_BLOCK_SIZE], eax
  mov eax, esi
  mov esi, [esi + ATTR_BLOCK_NEXT]
  cmp esi, NO_MORE
  jz _mem_split_block_done
  mov [esi + ATTR_BLOCK_PREV], eax
_mem_split_block_done:
  pop esi
  pop ebx
  pop eax
  pop ebp
  ret 8
  
  
mem_merge_free_block:
  ; input: block
  push ebp
  mov ebp, esp
  push eax
  push ebx
  push esi
  mov ebx, [ebp + 8]
  mov eax, [ebx]
  test eax, eax
  jnz _mem_merge_free_block_done
_mem_merge_free_block_find_head:
  mov esi, [ebx + ATTR_BLOCK_PREV]
  cmp esi, NO_MORE
  jz _mem_merge_free_block_do_merge
  mov eax, [esi]
  test eax, eax
  jnz _mem_merge_free_block_do_merge
  mov ebx, esi
  jmp _mem_merge_free_block_find_head
_mem_merge_free_block_do_merge:
  mov esi, [ebx + ATTR_BLOCK_NEXT]
  cmp esi, NO_MORE
  jz _mem_merge_free_block_done
  mov eax, [esi]
  test eax, eax
  jnz _mem_merge_free_block_done
  mov eax, [ebx + ATTR_BLOCK_SIZE]
  add eax, [esi + ATTR_BLOCK_SIZE]
  add eax, BLOCK_STRUCT_SIZE
  mov [ebx + ATTR_BLOCK_SIZE], eax
  mov eax, [esi + ATTR_BLOCK_NEXT]
  mov [ebx + ATTR_BLOCK_NEXT], eax
  mov esi, eax
  mov [esi + ATTR_BLOCK_PREV], ebx
  mov eax, [FREE_BLOCK_SIZE]
  add eax, BLOCK_STRUCT_SIZE
  mov [FREE_BLOCK_SIZE], eax
  jmp _mem_merge_free_block_do_merge
_mem_merge_free_block_done:
  pop esi
  pop ebx
  pop eax
  pop ebp
  ret 4
  
  
_mem_alloc:
  ; input: size; output: ax=address
  push ebp
  mov ebp, esp
  push ebx
  mov eax, [ebp + 8]
  test eax, 1
  jz _mem_alloc_size_aligned
  inc eax
  mov [ebp + 8], eax
_mem_alloc_size_aligned:
  push eax
  call mem_find_free_block
  cmp eax, NO_MORE
  jz _mem_alloc_done
  mov ebx, eax
  mov eax, [ebp + 8]
  push eax
  push ebx
  call mem_split_block
  mov eax, 1
  mov [ebx + ATTR_BLOCK_FLAG], eax
  mov eax, [ebx + ATTR_BLOCK_SIZE]
  add eax, [USED_BLOCK_SIZE]
  mov [USED_BLOCK_SIZE], eax
  mov eax, [FREE_BLOCK_SIZE]
  sub eax, [ebx + ATTR_BLOCK_SIZE]
  mov [FREE_BLOCK_SIZE], eax
  mov eax, ebx
_mem_alloc_done:
  pop ebx
  pop ebp
  ret 4
  
  
_mem_dealloc:
  ; input: block
  push ebp
  mov ebp, esp
  push eax
  push ecx
  push ebx
  mov ebx, [ebp + 8]
  mov ecx, [ebx + ATTR_BLOCK_SIZE]
  mov eax, [ebx + ATTR_BLOCK_FLAG]
  test eax, eax
  jz _mem_dealloc_done
  xor eax, eax
  mov [ebx + ATTR_BLOCK_FLAG], eax
  push ebx
  call mem_merge_free_block
  mov eax, [FREE_BLOCK_SIZE]
  add eax, ecx
  mov [FREE_BLOCK_SIZE], eax
_mem_dealloc_done:
  pop ebx
  pop ecx
  pop eax
  pop ebp
  ret 4
  
  
_get_free_block_size:
  mov eax, [FREE_BLOCK_SIZE]
  ret
  
  
_get_used_block_size:
  mov eax, [USED_BLOCK_SIZE]
  ret
  
  
_mem_get_data_offset:
  ; input: block; output: ax
  push ebp
  mov ebp, esp
  mov eax, [ebp + 8]
  cmp eax, NO_MORE
  jz _mem_get_data_offset_done
  add eax, BLOCK_STRUCT_SIZE
_mem_get_data_offset_done:
  pop ebp
  ret 4
  
  
_mem_get_container_block:
  ; input object; output: ax
  push ebp
  mov ebp, esp
  mov eax, [ebp + 8]
  sub eax, BLOCK_STRUCT_SIZE
  pop ebp
  ret 4
  
  
mem_copy:
  ; input: source, dest, length
  push ebp
  mov ebp, esp
  push eax
  push ecx
  push esi
  push edi
  push es
  push ds
  pop es
  mov esi, [ebp + 8]
  mov edi, [ebp + 12]
  mov ecx, [ebp + 16]
  test ecx, ecx
  jz _mem_copy_done
  cld
  cmp esi, edi
  jz _mem_copy_done
  jnc _mem_copy_start
  std
  mov eax, ecx
  dec eax
  add esi, eax
  add edi, eax
_mem_copy_start:
  rep
  movsb
_mem_copy_done:
  pop es
  pop edi
  pop esi
  pop ecx
  pop eax
  pop ebp
  ret 12
  
  
mem_reverse:
  ; input: offset, length; output: none
  push ebp
  mov ebp, esp
  push eax
  push ecx
  push esi
  push edi
  mov ecx, [ebp + 12]
  mov esi, [ebp + 8]
  mov edi, esi
  add edi, ecx
  dec edi
_mem_reverse_loop:
  mov al, [esi]
  mov ah, [edi]
  mov [edi], al
  mov [esi], ah
  inc esi
  dec edi
  cmp esi, edi
  jb _mem_reverse_loop
  pop edi
  pop esi
  pop ecx
  pop eax
  pop ebp
  ret 8
  
  
;mem_resize:
;  ; input: target_block, new_size; output: ax
;  push bp
;  mov bp, sp
;  push cx
;  push bx
;  mov ax, [bp + 6]
;  test ax, 1
;  jz _mem_resize_new_size_aligned
;  inc ax
;  mov [bp + 6], ax
;_mem_resize_new_size_aligned:
;  mov bx, [bp + 4]
;  mov ax, [bx + 2]
;  cmp ax, [bp + 6]
;  jz _mem_resize_skip
;  jc _mem_resize_expand
;_mem_resize_shrink:
;  mov ax, [bp + 6]
;  push ax
;  mov ax, [bp + 4]
;  push ax
;  call mem_split_block
;  jmp _mem_resize_fail
;_mem_resize_expand:
;  mov ax, [bp + 6]
;  push ax
;  call mem_alloc
;  cmp ax, NO_MORE
;  jz _mem_resize_fail
;  push ax
;  mov cx, [bx + 2]
;  push cx
;  push ax
;  call mem_get_data_offset
;  push ax
;  push bx
;  call mem_get_data_offset
;  push ax
;  call mem_copy
;  mov ax, [bp + 4]
;  push ax
;  call mem_dealloc
;  pop ax
;  jmp _mem_resize_done
;_mem_resize_skip:
;_mem_resize_fail:
;  mov ax, [bp + 4]
;_mem_resize_done:
;  pop bx
;  pop cx
;  pop bp
;  ret 4
  
  
; mem_expand_if_needed:
  ; ; input: target block, new size; output: old/new block address or NO_MORE
  ; push bp
  ; mov bp, sp
  ; push cx
  ; push bx
  ; mov ax, [bp + 6]
  ; test ax, 1
  ; jz _mem_expand_if_needed_new_size_aligned
  ; inc ax
  ; mov [bp + 6], ax
; _mem_expand_if_needed_new_size_aligned:
  ; mov bx, [bp + 4]
  ; mov ax, [bx + 2]
  ; cmp ax, [bp + 6]
  ; jnc _mem_expand_if_needed_skip
  ; mov ax, [bp + 6]
  ; push ax
  ; call mem_alloc
  ; cmp ax, NO_MORE
  ; jz _mem_expand_if_needed_fail
  ; push ax
  ; mov cx, [bx + 2]
  ; push cx
  ; push ax
  ; call mem_get_data_offset
  ; push ax
  ; push bx
  ; call mem_get_data_offset
  ; push ax
  ; call mem_copy
  ; mov ax, [bp + 4]
  ; push ax
  ; call mem_dealloc
  ; pop ax
  ; jmp _mem_expand_if_needed_done
; _mem_expand_if_needed_skip:
; _mem_expand_if_needed_fail:
  ; mov ax, [bp + 4]
; _mem_expand_if_needed_done:
  ; pop bx
  ; pop cx
  ; pop bp
  ; ret 4
  
  
; _is_object:
  ; ; input: object; output: ZF=1 if object, else ZF=0
  ; push bp
  ; mov bp, sp
  ; push ax
  ; mov ax, [bp + 4]
  ; test ax, 1
  ; jnz _is_object_done
  ; test ax, CLS_ID_NULL
  ; jz _is_object_false
  ; test ax, CLS_ID_TRUE
  ; jz _is_object_false
  ; test ax, CLS_ID_FALSE
  ; jnz _is_object_done
; _is_object_false:
  ; or ax, 1
; _is_object_done:
  ; pop ax
  ; pop bp
  ; ret 2
  
  
_alloc_object:
  ; input: class id, instance variable count
  push ebp
  mov ebp, esp
  push ebx
  mov eax, [ebp + 12]
  add eax, 1
  shl eax, 2
  push eax
  call mem_alloc
  cmp eax, NO_MORE
  jz _alloc_object_done
  push eax
  call mem_get_data_offset
  push eax
  mov ebx, eax
  mov eax, [ebp + 8]
  mov [ebx + ATTR_OBJ_CLASS_ID], eax
  pop eax
_alloc_object_done:
  pop ebx
  pop ebp
  ret 8
  
  
; increment_object_ref:
  ; ; input: object; output: none
  ; push bp
  ; mov bp, sp
  ; push ax
  ; push si
  ; mov ax, [bp + 4]
  ; push ax
  ; call mem_get_container_block
  ; mov si, ax
  ; mov ax, [si]
  ; cmp ax, MAX_REF_COUNT
  ; jz _increment_object_ref_done
  ; inc ax
  ; mov [si], ax
; _increment_object_ref_done:
  ; pop si
  ; pop ax
  ; pop bp
  ; ret 2
  
  
; decrement_object_ref:
  ; ; input: object; output: none
  ; push bp
  ; mov bp, sp
  ; push ax
  ; push si
  ; mov ax, [bp + 4]
  ; push ax
  ; call mem_get_container_block
  ; mov si, ax
  ; mov ax, [si]
  ; cmp ax, GARBAGE
  ; jz _decrement_object_ref_done
  ; dec ax
  ; test ax, ax
  ; jnz _decrement_object_ref_set_counter
  ; inc word [GARBAGE_COUNT]
  ; mov ax, GARBAGE
; _decrement_object_ref_set_counter:
  ; mov [si], ax
; _decrement_object_ref_done:
  ; pop si
  ; pop ax
  ; pop bp
  ; ret 2
  
  
; destroy_object:
  ; ; input: object; output: nothing
  ; push bp
  ; mov bp, sp
  ; push ax
  ; push cx
  ; push si
  ; mov ax, [bp + 4]
  ; push ax
  ; call _is_object
  ; jnz _destroy_object_done
  ; push ax
  ; call mem_get_container_block
  ; mov si, ax
  ; mov ax, [si + 2]
  ; shr ax, 1
  ; dec ax
  ; test ax, ax
  ; jz _destroy_object_done
  ; mov cx, ax
  ; mov si, [bp + 4]
; _destroy_object_destroy_child:
  ; add si, 2
  ; mov ax, [si]
  ; push ax
  ; call destroy_object
  ; loop _destroy_object_destroy_child
  ; mov si, [bp + 4]
  ; mov ax, GARBAGE
  ; cmp ax, [si]
  ; jz _destroy_object_done
  ; mov [si], ax
  ; inc word [GARBAGE_COUNT]
; _destroy_object_done:
  ; pop si
  ; pop cx
  ; pop ax
  ; pop bp
  ; ret 2
  
  
; mark_garbages:
  ; ; input: none; output: none
  ; push ax
  ; push bx
  ; mov bx, [FIRST_BLOCK]
; _mark_garbages_check_block:
  ; mov ax, [bx]
  ; cmp ax, GARBAGE
  ; jnz _mark_garbages_object_destroyed
  ; push bx
  ; call destroy_object
; _mark_garbages_object_destroyed:
  ; mov bx, [bx + 6]
  ; cmp bx, NO_MORE
  ; jnz _mark_garbages_check_block
; _mark_garbages_done:
  ; pop bx
  ; pop ax
  ; ret
  
  
; collect_garbage:
  ; ; input: none; output: none
  ; push ax
  ; push bx
  ; push si
  ; call mark_garbages
  ; mov bx, [FIRST_BLOCK]
; _collect_garbage_check_block:
  ; mov ax, [bx]
  ; cmp ax, GARBAGE
  ; jnz _collect_garbage_block_checked
  ; xor ax, ax
  ; mov [bx], ax
  ; mov si, bx
  ; mov ax, [si + 6]
  ; cmp ax, NO_MORE
  ; jz _collect_garbage_next_block_found
  ; push si
  ; mov ax, [si]
  ; pop si
  ; test ax, ax
  ; jnz _collect_garbage_next_block_found
  ; mov si, ax
; _collect_garbage_next_block_found:
  ; push bx
  ; call mem_dealloc
  ; mov bx, si
; _collect_garbage_block_checked:
  ; mov bx, [bx + 6]
  ; cmp bx, NO_MORE
  ; jnz _collect_garbage_check_block
  ; xor ax, ax
  ; mov [GARBAGE_COUNT], ax
; _collect_garbage_done:
  ; pop si
  ; pop bx
  ; pop ax
  ; ret
  
  
; collect_garbage_if_needed:
  ; push ax
  ; mov ax, [GARBAGE_COUNT]
  ; test ax, ax
  ; jz _collect_garbage_if_needed_skip
  ; push cx
  ; push dx
  ; call get_free_block_size
  ; mov cx, ax
  ; call get_used_block_size
  ; add cx, ax
  ; shr cx, 2
  ; cmp ax, cx
  ; jc _collect_garbage_if_needed_done
  ; call collect_garbage
; _collect_garbage_if_needed_done:
  ; pop dx
  ; pop cx
; _collect_garbage_if_needed_skip:
  ; pop ax
  ; ret
  
  
; unassign_object:
  ; ; input: object; output: nothing
  ; push bp
  ; mov bp, sp
  ; push ax
  ; mov ax, [bp + 4]
  ; push ax
  ; call _is_object
  ; jnz _unassign_object_done
  ; push ax
  ; call decrement_object_ref
  ; call collect_garbage_if_needed
; _unassign_object_done:
  ; pop ax
  ; pop bp
  ; ret 2
  
  
create_str:
  ; input: length; output: ax=str object or zero if fail
  push ebp
  mov ebp, esp
  push esi
  mov eax, [ebp + 8]
  push eax
  call mem_alloc
  cmp eax, NO_MORE
  jnz _create_str_alloc_success
  mov eax, CLS_ID_NULL
  jmp _create_str_failed
_create_str_alloc_success:
  push eax
  call mem_get_data_offset
  mov esi, eax                                ; si = data offset
  mov eax, 2                                  ; instance_variable count
  push eax
  mov eax, CLS_ID_STRING                      ; class_id
  push eax
  call alloc_object
  cmp eax, NO_MORE
  jz _create_str_failed
  xchg esi, eax                               ; si = string object, ax = data offset
  mov [esi + ATTR_OBJ_DATA_OFFSET], eax
  mov eax, [ebp + 8]
  mov [esi + ATTR_STR_LENGTH], eax
  mov eax, esi
_create_str_failed:
  pop esi
  pop ebp
  ret 4
  
  
_load_str:
  ; input: offset; output: ax
  ; string structure:
  ; - class id
  ; - string length
  ; - buffer location
  push ebp
  mov ebp, esp
  push ebx
  push esi
  mov ebx, [ebp + 8]
  mov eax, [ebx]
  push eax
  call create_str
  cmp eax, CLS_ID_NULL
  jz _load_str_failed
  mov esi, eax
  mov eax, [ebx]
  push eax
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  push eax
  mov eax, ebx
  add eax, 4
  push eax
  call mem_copy
  mov eax, esi
_load_str_failed:
  pop esi
  pop ebx
  pop ebp
  ret 4
  
  
_str_length:
  ; input: str; output: ax
  push ebp
  mov ebp, esp
  push ebx
  mov ebx, [ebp + 8]
  mov eax, [ebx + ATTR_STR_LENGTH]
  pop ebx
  pop ebp
  ret 4
  
_str_copy:
  ; input str; output: ax
  ; create a copy of existing string
  push ebp
  mov ebp, esp
  push esi
  push edi
  mov esi, [ebp + 8]
  mov eax, [esi + ATTR_STR_LENGTH]
  push eax
  call create_str
  cmp eax, CLS_ID_NULL
  jz _str_copy_failed
  mov edi, eax
  mov eax, [esi + ATTR_STR_LENGTH]
  push eax
  mov eax, [edi + ATTR_OBJ_DATA_OFFSET]
  push eax
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  push eax
  call mem_copy
  mov eax, edi
_str_copy_failed:
  pop edi
  pop esi
  pop ebp
  ret 4
  
  
str_expand:
  ; input: str, append_size; output: CF set if failed
  ; copy str length first before calling this function
  ; because it may changed
  push ebp
  mov ebp, esp
  push eax
  push ecx
  push ebx
  push esi
  mov esi, [ebp + 8]
  mov ebx, [esi + ATTR_OBJ_DATA_OFFSET]
  mov ecx, [ebp + 12]
  test ecx, ecx
  jz _str_expand_success
  add ecx, [esi + ATTR_STR_LENGTH]
  cmp ecx, [ebx - BLOCK_STRUCT_SIZE + ATTR_BLOCK_SIZE]
  jnc _str_expand_update_size
  mov eax, ecx
  shr eax, 1
  add eax, ecx
  push eax
  call mem_alloc
  cmp eax, CLS_ID_NULL
  jz _str_expand_failed
  push eax
  call mem_get_data_offset
  mov ebx, eax
  mov eax, [esi + ATTR_STR_LENGTH]
  push eax
  push ebx
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  push eax
  call mem_copy
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  sub eax, BLOCK_STRUCT_SIZE
  push eax
  call mem_dealloc
  mov [esi + ATTR_OBJ_DATA_OFFSET], ebx
_str_expand_update_size:
  mov [esi + ATTR_STR_LENGTH], ecx
_str_expand_success:
  clc
  jmp _str_expand_done
_str_expand_failed:
  stc
_str_expand_done:
  pop esi
  pop ebx
  pop ecx
  pop eax
  pop ebp
  ret 8
  
  
_str_concat:
  ; input: str1, str2; output: ax=new str or zero if fail
  push ebp
  mov ebp, esp
  push ecx
  push ebx
  push esi
  push edi
  mov esi, [ebp + 8]
  mov edi, [ebp + 12]
  mov ecx, [esi + ATTR_STR_LENGTH]
  add ecx, [edi + ATTR_STR_LENGTH]
  push ecx
  call create_str
  cmp eax, CLS_ID_NULL
  jz _str_concat_failed
  mov ebx, eax
  mov eax, [esi + ATTR_STR_LENGTH]
  push eax
  mov eax, [ebx + ATTR_OBJ_DATA_OFFSET]
  push eax
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  push eax
  call mem_copy
  mov eax, [edi + ATTR_STR_LENGTH]
  push eax
  mov eax, [ebx + ATTR_OBJ_DATA_OFFSET]
  add eax, [esi + ATTR_STR_LENGTH]
  push eax
  mov eax, [edi + ATTR_OBJ_DATA_OFFSET]
  push eax
  call mem_copy
  mov eax, ebx
_str_concat_failed:
  pop edi
  pop esi
  pop ebx
  pop ecx
  pop ebp
  ret 8
  
  
_str_substr:
  ; input: str, offset, size; output: ax
  push ebp
  mov ebp, esp
  push esi
  push edi
  mov eax, [ebp + 16]
  push eax
  call create_str
  cmp eax, CLS_ID_NULL
  jz _str_substr_failed
  mov edi, eax
  mov esi, [ebp + 8]
  mov eax, [ebp + 16]
  push eax
  mov eax, [edi + ATTR_OBJ_DATA_OFFSET]
  push eax
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  add eax, [ebp + 12]
  push eax
  call mem_copy
  mov eax, edi
_str_substr_failed:
  pop edi
  pop esi
  pop ebp
  ret 12
  
  
_str_lcase:
  ; input: str; output: ax
  push ebp
  mov ebp, esp
  push ecx
  push ebx
  push esi
  mov eax, [ebp + 8]
  push eax
  call str_copy
  cmp eax, CLS_ID_NULL
  jz _str_lcase_done
  mov ebx, eax
  mov ecx, [ebx +  ATTR_STR_LENGTH]
  test ecx, ecx
  jz _str_lcase_processed
  mov esi, [ebx + ATTR_OBJ_DATA_OFFSET]
_str_lcase_loop:
  mov al, [esi]
  cmp al, 41h
  jc _str_lcase_skip_char
  cmp al, 5ah
  jg _str_lcase_skip_char
  add al, 20h
  mov [esi], al
_str_lcase_skip_char:
  inc esi
  loop _str_lcase_loop
_str_lcase_processed:
  mov eax, ebx
_str_lcase_done:
  pop esi
  pop ebx
  pop ecx
  pop ebp
  ret 4
  
  
_str_ucase:
  ; input: str; output: ax
  push ebp
  mov ebp, esp
  push ecx
  push ebx
  push esi
  mov eax, [ebp + 8]
  push eax
  call str_copy
  cmp eax, CLS_ID_NULL
  jz _str_ucase_done
  mov ebx, eax
  mov ecx, [ebx +  ATTR_STR_LENGTH]
  test ecx, ecx
  jz _str_ucase_processsed
  mov esi, [ebx + ATTR_OBJ_DATA_OFFSET]
_str_ucase_loop:
  mov al, [esi]
  cmp al, 61h
  jc _str_ucase_skip_char
  cmp al, 7ah
  jg _str_ucase_skip_char
  sub al, 20h
  mov [esi], al
_str_ucase_skip_char:
  inc esi
  loop _str_ucase_loop
_str_ucase_processsed:
  mov eax, ebx
_str_ucase_done:
  pop esi
  pop ebx
  pop ecx
  pop ebp
  ret 4
  
  
_str_append:
  ; input: dst, src; output: CF set if failed
  push ebp
  mov ebp, esp
  push eax
  push ecx
  push ebx
  push esi
  push edi
  mov esi, [ebp + 8]
  mov edi, [ebp + 12]
  mov ecx, [esi + ATTR_STR_LENGTH]
  mov eax, [edi + ATTR_STR_LENGTH]
  push eax
  push esi
  call str_expand
  jc _str_append_failed
  mov eax, [edi + ATTR_STR_LENGTH]
  push eax
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  add eax, ecx
  push eax
  mov eax, [edi + ATTR_OBJ_DATA_OFFSET]
  push eax
  call mem_copy
_str_append_success:
  clc
  jmp _str_append_done
_str_append_failed:
  stc
_str_append_done:
  pop edi
  pop esi
  pop ebx
  pop ecx
  pop eax
  pop ebp
  ret 8
  
  
_str_append_chr:
  ; input: str, chr; output: CF set if failed
  push ebp
  mov ebp, esp
  push eax
  push ebx
  push esi
  mov esi, [ebp + 8]
  mov eax, [ebp + 12]
  push dword 1
  push esi
  call str_expand
  jc _str_append_chr_failed
  mov ebx, [esi + ATTR_OBJ_DATA_OFFSET]
  add ebx, [esi + ATTR_STR_LENGTH]
  mov [ebx - 1], al
_str_append_chr_success:
  clc
  jmp _str_append_chr_done
_str_append_chr_failed:
  stc
_str_append_chr_done:
  pop esi
  pop ebx
  pop eax
  pop ebp
  ret 8
  
  
_str_reverse:
  ; input: str object; output: ax
  push ebp
  mov ebp, esp
  push ecx
  push ebx
  push esi
  push edi
  mov esi, [ebp + 8]
  mov eax, [esi + ATTR_STR_LENGTH]
  push eax
  call create_str
  mov ebx, eax
  mov ecx, [esi + ATTR_STR_LENGTH]
  test ecx, ecx
  jz _str_reverse_done
  mov eax, [esi + ATTR_OBJ_DATA_OFFSET]
  add eax, ecx
  dec eax
  mov esi, eax
  mov edi, [ebx + ATTR_OBJ_DATA_OFFSET]
_str_reverse_copy:
  mov al, [esi]
  mov [edi], al
  dec esi
  inc edi
  loop _str_reverse_copy
_str_reverse_done:
  mov eax, ebx
  pop edi
  pop esi
  pop ebx
  pop ecx
  pop ebp
  ret 4
  
  
; ;str_strip:
; ;str_truncate:
; ;str_shift:
; ;str_prepend:
; ;str_insert:
  
  
; _cbw:
  ; ; input: value; output: ax
  ; push bp
  ; mov bp, sp
  ; mov ax, [bp + 4]
  ; cbw
  ; pop bp
  ; ret 2
  
  
; _cwb:
  ; ; input: value; output: ax
  ; push bp
  ; mov bp, sp
  ; mov ax, [bp + 4]
  ; xor ah, ah
  ; pop bp
  ; ret 2
  
  
; _get_byte_at:
  ; ; input: offset, index; output: al
  ; push bp
  ; mov bp, sp
  ; push si
  ; mov si, [bp + 4]
  ; add si, [bp + 6]
  ; mov al, [si]
  ; pop si
  ; pop bp
  ; ret 4
  
  
; _set_byte_at:
  ; ; input: offset, index, value
  ; push bp
  ; mov bp, sp
  ; push ax
  ; push si
  ; mov si, [bp + 4]
  ; add si, [bp + 6]
  ; mov ax, [bp + 8]
  ; mov [si], al
  ; pop si
  ; pop ax
  ; pop bp
  ; ret 6
  
  
; _get_word_at:
  ; ; input: offset, index; output: ax
  ; push bp
  ; mov bp, sp
  ; push si
  ; mov si, [bp + 4]
  ; add si, [bp + 6]
  ; mov ax, [si]
  ; pop si
  ; pop bp
  ; ret 4
  
  
; _set_word_at:
  ; ; input: offset, index, value
  ; push bp
  ; mov bp, sp
  ; push ax
  ; push si
  ; mov si, [bp + 4]
  ; add si, [bp + 6]
  ; mov ax, [bp + 8]
  ; mov [si], ax
  ; pop si
  ; pop ax
  ; pop bp
  ; ret 6
  
  
_int_pack:
  ; input: value; output: ax
  push ebp
  mov ebp, esp
  mov eax, [ebp + 8]
  shl eax, 1
  or eax, 1
  pop ebp
  ret 4
  
  
_int_unpack:
  ; input: value; output: ax
  push ebp
  mov ebp, esp
  mov eax, [ebp + 8]
  shr eax, 1
  test eax, 40000000h
  jz _int_unpack_done
  or eax, 80000000h
_int_unpack_done:
  pop ebp
  ret 4
  
  
; _int_add:
  ; ; input: v1, v2; output: ax
  ; push bp
  ; mov bp, sp
  ; push cx
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; mov cx, ax
  ; mov ax, [bp + 4]
  ; push ax
  ; call _int_unpack
  ; add ax, cx
  ; push ax
  ; call _int_pack
  ; pop cx
  ; pop bp
  ; ret 4
  
  
; _int_subtract:
  ; ; input: v1, v2; output: ax
  ; push bp
  ; mov bp, sp
  ; push cx
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; mov cx, ax
  ; mov ax, [bp + 4]
  ; push ax
  ; call _int_unpack
  ; sub ax, cx
  ; push ax
  ; call _int_pack
  ; pop cx
  ; pop bp
  ; ret 4
  
  
; _int_multiply:
  ; ; input: v1, v2; output: ax
  ; push bp
  ; mov bp, sp
  ; push cx
  ; push dx
  ; xor dx, dx
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; mov cx, ax
  ; mov ax, [bp + 4]
  ; push ax
  ; call _int_unpack
  ; imul cx
  ; push ax
  ; call _int_pack
  ; pop dx
  ; pop cx
  ; pop bp
  ; ret 4
  
  
; _int_divide:
  ; ; input: v1, v2; output: ax
  ; push bp
  ; mov bp, sp
  ; push cx
  ; push dx
  ; xor dx, dx
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; mov cx, ax
  ; mov ax, [bp + 4]
  ; push ax
  ; call _int_unpack
  ; idiv cx
  ; push ax
  ; call _int_pack
  ; pop dx
  ; pop cx
  ; pop bp
  ; ret 4
  
  
; _int_and:
  ; ; input: v1, v2; output: ax
  ; push bp
  ; mov bp, sp
  ; push cx
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; mov cx, ax
  ; mov ax, [bp + 4]
  ; push ax
  ; call _int_unpack
  ; and ax, cx
  ; push ax
  ; call _int_pack
  ; pop cx
  ; pop bp
  ; ret 4
  
  
; _int_or:
  ; ; input: v1, v2; output: ax
  ; push bp
  ; mov bp, sp
  ; push cx
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; mov cx, ax
  ; mov ax, [bp + 4]
  ; push ax
  ; call _int_unpack
  ; or ax, cx
  ; push ax
  ; call _int_pack
  ; pop cx
  ; pop bp
  ; ret 4
  
  
_nible_to_h:
  ; input: al; output: al
  and al, 0fh
  add al, 30h
  cmp al, 3ah
  jc _nible_to_h_done
  add al, 7
_nible_to_h_done:
  ret
  
  
_byte_to_h:
  ; input: al; output: ax
  mov ah, al
  call _nible_to_h
  xchg ah, al
  shr al, 4
  call _nible_to_h
  xchg ah, al
  ret
  
  
_int_to_h8:
  ; input: int; output: eax
  push ebp
  mov ebp, esp
  push ebx
  push esi
  push dword 2
  call create_str
  mov ebx, eax
  mov esi, [ebx + ATTR_OBJ_DATA_OFFSET]
  mov eax, [ebp + 8]
  call _byte_to_h
  xchg ah, al
  mov [esi], ax
  mov eax, ebx
  pop esi
  pop ebx
  pop ebp
  ret 4
  
  
_int_to_h16:
  ; input: int; output: ax
  push ebp
  mov ebp, esp
  push ebx
  push esi
  push dword 4
  call create_str
  mov ebx, eax
  mov esi, [ebx + ATTR_OBJ_DATA_OFFSET]
  mov eax, [ebp + 8]
  push eax
  call _byte_to_h
  xchg ah, al
  mov [esi + 2], ax
  pop eax
  xchg ah, al
  call _byte_to_h
  xchg ah, al
  mov [esi + 0], ax
  mov eax, ebx
  pop esi
  pop ebx
  pop ebp
  ret 4
  
  
_int_to_s:
  ; input: int; output: ax
  push ebp
  mov ebp, esp
  push ecx
  push edx
  push ebx
  push edi
  push dword 6
  call create_str
  mov ebx, eax
  xor eax, eax
  mov [ebx + ATTR_STR_LENGTH], eax
  mov edi, [ebx + ATTR_OBJ_DATA_OFFSET]
  mov eax, [ebp + 8]
  mov ecx, 10
_int_to_s_loop:
  xor edx, edx
  div cx
  push eax
  mov al, dl
  call _nible_to_h
  mov [edi], al
  inc edi
  inc dword [ebx + ATTR_STR_LENGTH]
  pop eax
  test eax, eax
  jnz _int_to_s_loop
  mov eax, [ebx + ATTR_STR_LENGTH]
  push eax
  mov eax, [ebx + ATTR_OBJ_DATA_OFFSET]
  push eax
  call mem_reverse
  mov eax, ebx
  pop edi
  pop ebx
  pop edx
  pop ecx
  pop ebp
  ret 4
  
  
_int_to_chr:
  ; input: int; output: ax
  push ebp
  mov ebp, esp
  push ebx
  push esi
  push dword 2
  call create_str
  mov ebx, eax
  mov eax, 1
  mov [ebx + ATTR_STR_LENGTH], eax
  mov esi, [ebx + ATTR_OBJ_DATA_OFFSET]
  mov eax, [ebp + 8]
  push eax
  call _int_unpack
  mov [esi], al
  mov eax, ebx
  pop esi
  pop ebx
  pop ebp
  ret 4
  
  
; _is_true:
  ; ; input: object; output: ZF
  ; push bp
  ; mov bp, sp
  ; push ax
  ; mov ax, [bp + 4]
  ; cmp ax, CLS_ID_TRUE
  ; jz _is_true_done
  ; cmp ax, CLS_ID_FALSE
  ; jz _is_true_false
  ; test ax, ax
  ; jmp _is_true_done
; _is_true_false:
  ; or ax, 1
; _is_true_done:
  ; pop ax
  ; pop bp
  ; ret 2
  
  
; _int_compare:
  ; ; should be called from compare function
  ; ; input: main caller, object1, object2; output: ax
  ; push bp
  ; mov bp, sp
  ; push si
  ; push di
  ; mov si, [bp + 6]
  ; mov di, [bp + 8]
  ; push si
  ; call _is_object
  ; jz _int_compare_false
  ; push di
  ; call _is_object
  ; jz _int_compare_false
  ; mov ax, _int_compare_done
  ; add ax, CODE_BASE_ADDRESS
  ; push ax
  ; mov ax, [bp + 2]
  ; push ax
  ; mov ax, CLS_ID_TRUE
  ; cmp si, di
  ; ret
; _int_compare_false:
  ; mov ax, CLS_ID_FALSE
; _int_compare_done:
  ; pop di
  ; pop si
  ; pop bp
  ; add sp, 2
  ; ret 4
  
  
; _is_equal:
  ; ; input: object1, object2; output: ax
  ; call _int_compare
  ; jz _is_equal_done
  ; mov ax, CLS_ID_FALSE
; _is_equal_done:
  ; ret
  
  
; _is_not_equal:
  ; ; input: object1, object2; output: ax
  ; call _int_compare
  ; jnz _is_not_equal_done
  ; mov ax, CLS_ID_FALSE
; _is_not_equal_done:
  ; ret
  
  
; _is_less_than:
  ; ; input: object1, object2; output: ax
  ; call _int_compare
  ; jl _is_less_than_done
  ; mov ax, CLS_ID_FALSE
; _is_less_than_done:
  ; ret
  
  
; _is_less_than_or_equal:
  ; ; input: object1, object2; output: ax
  ; call _int_compare
  ; jle _is_less_than_or_equal_done
  ; mov ax, CLS_ID_FALSE
; _is_less_than_or_equal_done:
  ; ret
  
  
; _is_greater_than:
  ; ; input: object1, object2; output: ax
  ; call _int_compare
  ; jg _is_greater_done
  ; mov ax, CLS_ID_FALSE
; _is_greater_done:
  ; ret
  
  
; _is_greater_than_or_equal:
  ; ; input: object1, object2; output: ax
  ; call _int_compare
  ; jge _is_greater_than_or_equal_done
  ; mov ax, CLS_ID_FALSE
; _is_greater_than_or_equal_done:
  ; ret
  
  
; _create_array:
  ; ; creates empty array
  ; ; input: none; output: array object
  ; push bx
  ; push si
  ; xor ax, ax
  ; push ax
  ; call mem_alloc
  ; cmp ax, NO_MORE
  ; jz _create_array_done
  ; push ax
  ; call mem_get_data_offset
  ; mov si, ax
  ; mov ax, 2                 ; iv count: length, data offset
  ; push ax
  ; mov ax, CLS_ID_ARRAY
  ; push ax
  ; call alloc_object
  ; cmp ax, NO_MORE
  ; jz _create_array_done
  ; mov bx, ax
  ; xor ax, ax
  ; push ax
  ; call _int_pack
  ; mov [bx + 2], ax          ; element count
  ; mov [bx + 4], si          ; data offset
  ; mov ax, bx
; _create_array_done:
  ; pop si
  ; pop bx
  ; ret
  
  
; _array_length:
  ; ; input: array; output: ax
  ; push bp
  ; mov bp, sp
  ; push bx
  ; mov bx, [bp + 4]
  ; mov ax, [bx + 2]
  ; pop bx
  ; pop bp
  ; ret 2
  
  
; _array_get_item:
  ; ; input: array, index; output: ax
  ; push bp
  ; mov bp, sp
  ; push bx
  ; push si
  ; mov bx, [bp + 4]
  ; mov si, [bx + 4]
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; shl ax, 1
  ; add si, ax
  ; mov ax, [si]
  ; pop si
  ; pop bx
  ; pop bp
  ; ret 4
  
  
; _array_set_item:
  ; ; input: array, index, value
  ; push bp
  ; mov bp, sp
  ; push ax
  ; push bx
  ; push si
  ; mov bx, [bp + 4]
  ; mov si, [bx + 4]
  ; mov ax, [bp + 6]
  ; push ax
  ; call _int_unpack
  ; shl ax, 1
  ; add si, ax
  ; mov ax, [bp + 8]
  ; mov [si], ax
  ; pop si
  ; pop bx
  ; pop ax
  ; pop bp
  ; ret 6
  
  
; _array_append:
  ; ; input: array, value; output: array object
  ; push bp
  ; mov bp, sp
  ; push bx
  ; push si
  ; mov bx, [bp + 4]
  ; mov ax, [bx + 2]
  ; push ax
  ; call _int_unpack
  ; inc ax
  ; shl ax, 1
  ; push ax
  ; mov ax, [bx + 4]
  ; push ax
  ; call mem_get_container_block
  ; push ax
  ; call mem_expand_if_needed
  ; cmp ax, NO_MORE
  ; jz _array_append_failed
  ; push ax
  ; call mem_get_data_offset
  ; cmp ax, [bx + 4]
  ; jz _array_append_block_relocated
  ; mov [bx + 4], ax
; _array_append_block_relocated:
  ; mov si, [bx + 4]
  ; mov ax, [bx + 2]
  ; push ax
  ; call _int_unpack
  ; shl ax, 1
  ; add si, ax
  ; mov ax, [bp + 6]
  ; mov [si], ax
  ; mov ax, [bx + 2]
  ; push ax
  ; call _int_unpack
  ; inc ax
  ; push ax
  ; call _int_pack
  ; mov [bx + 2], ax
; _array_append_failed:
  ; mov ax, bx
  ; pop si
  ; pop bx
  ; pop bp
  ; ret 4
  
  
; _get_obj_var:
  ; ; input: object, var-index
  ; push bp
  ; mov bp, sp
  ; push si
  ; mov si, [bp + 4]
  ; mov ax, [bp + 6]
  ; add ax, 1
  ; shl ax, 1
  ; add si, ax
  ; mov ax, [si]
  ; pop si
  ; pop bp
  ; ret 4
  
  
; _set_obj_var:
  ; ; input: object, var-index, value
  ; push bp
  ; mov bp, sp
  ; push ax
  ; push si
  ; mov si, [bp + 4]
  ; mov ax, [bp + 6]
  ; add ax, 1
  ; shl ax, 1
  ; add si, ax
  ; push si
  ; call unassign_object
  ; mov ax, [bp + 8]
  ; mov [si], ax
  ; pop si
  ; pop ax
  ; pop bp
  ; ret 6
  
  
puts:
  ; input: str object
  jmp print
