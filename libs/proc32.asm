; written by Heryudi Praja

ARGUMENT1                 EQU 2 * REG_BYTE_SIZE
ARGUMENT2                 EQU 3 * REG_BYTE_SIZE
ARGUMENT3                 EQU 4 * REG_BYTE_SIZE
ARGUMENT4                 EQU 5 * REG_BYTE_SIZE
ARGUMENT5                 EQU 6 * REG_BYTE_SIZE

NO_MORE                   EQU -1
FAILED                    EQU -1
GARBAGE                   EQU -1
MAX_REF_COUNT             EQU -2
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
ATTR_ARY_LENGTH           EQU 4
ATTR_OBJ_DATA_OFFSET      EQU 8

; reserved system data
FIRST_BLOCK               EQU 0
FREE_BLOCK_SIZE           EQU 4
USED_BLOCK_SIZE           EQU 8
GARBAGE_COUNT             EQU 12


pass_arguments:
  ; input: function, mandatory_count, optional count, arguments
  ; return value should be put at [bp - 4]
  push r_bp
  mov r_bp, r_sp
  push r_ax
  mov r_ax, _pass_arguments_return
  push r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  ret
_pass_arguments_return:
  push r_si
  mov r_si, r_bp
  mov r_ax, [r_bp + ARGUMENT2]
  add r_ax, [r_bp + ARGUMENT3]
  add r_ax, 5
  shl r_ax, REG_SIZE_BITS
  add r_si, r_ax
  mov r_ax, [r_bp + REG_BYTE_SIZE]
  xchg r_bp, r_si
  mov [r_bp], r_ax
  xchg r_bp, r_si
  mov [r_bp + REG_BYTE_SIZE], r_si
  pop r_si
  pop r_ax
  pop r_bp
  pop r_sp
  ret
  
  
set_result:
  mov [r_bp - REG_BYTE_SIZE], r_ax
  ret
  
  
mem_block_init:
  ; input: offset, size; output: none
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_bx
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bp + ARGUMENT2]
  cmp r_ax, BLOCK_STRUCT_SIZE
  jc _mem_block_init_done
  sub r_ax, BLOCK_STRUCT_SIZE
  mov [FREE_BLOCK_SIZE], r_ax
  mov [r_bx + ATTR_BLOCK_SIZE], r_ax    ; data size
  mov r_ax, NO_MORE
  mov [r_bx + ATTR_BLOCK_PREV], r_ax    ; prev block
  mov [r_bx + ATTR_BLOCK_NEXT], r_ax    ; next block
  xor r_ax, r_ax
  mov [r_bx + ATTR_BLOCK_FLAG], r_ax    ; flag
_mem_block_init_done:
  xor r_ax, r_ax
  mov [USED_BLOCK_SIZE], r_ax
  mov [GARBAGE_COUNT], r_ax
  mov [FIRST_BLOCK], r_bx
  pop r_bx
  pop r_ax
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
mem_find_free_block:
  ; input: size; output ax: address
  push r_bp
  mov r_bp, r_sp
  push r_bx
  mov r_bx, [FIRST_BLOCK]
_mem_find_free_block_check_current_block:
  mov r_ax, [r_bx + ATTR_BLOCK_FLAG]
  test r_ax, r_ax
  jnz _mem_find_free_block_block_checked
  mov r_ax, [r_bx + ATTR_BLOCK_SIZE]
  cmp r_ax, [r_bp + ARGUMENT1]
  jc _mem_find_free_block_block_checked
  mov r_ax, r_bx
  jmp _mem_find_free_block_done
_mem_find_free_block_block_checked:
  mov r_bx, [r_bx + ATTR_BLOCK_NEXT]
  cmp r_bx, NO_MORE
  jnz _mem_find_free_block_check_current_block
  mov r_ax, r_bx
_mem_find_free_block_done:
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
mem_split_block:
  ; input: block, size
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_bx
  push r_si
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx + ATTR_BLOCK_SIZE]
  sub r_ax, [r_bp + ARGUMENT2]
  jc _mem_split_block_done
  sub r_ax, BLOCK_STRUCT_SIZE
  jc _mem_split_block_done
  mov r_ax, [r_bp + ARGUMENT2]
  add r_ax, BLOCK_STRUCT_SIZE
  add r_ax, r_bx
  mov r_si, r_ax
  xor r_ax, r_ax
  mov [r_si + ATTR_BLOCK_FLAG], r_ax
  mov r_ax, [r_bx + ATTR_BLOCK_SIZE]
  sub r_ax, [r_bp + ARGUMENT2]
  sub r_ax, BLOCK_STRUCT_SIZE
  mov [r_si + ATTR_BLOCK_SIZE], r_ax
  mov [r_si + ATTR_BLOCK_PREV], r_bx
  mov r_ax, [r_bx + ATTR_BLOCK_NEXT]
  mov [r_si + ATTR_BLOCK_NEXT], r_ax
  mov r_ax, [r_bp + ARGUMENT2]
  mov [r_bx + ATTR_BLOCK_SIZE], r_ax
  mov [r_bx + ATTR_BLOCK_NEXT], r_si
  mov r_ax, [FREE_BLOCK_SIZE]
  sub r_ax, BLOCK_STRUCT_SIZE
  mov [FREE_BLOCK_SIZE], r_ax
  mov r_ax, r_si
  mov r_si, [r_si + ATTR_BLOCK_NEXT]
  cmp r_si, NO_MORE
  jz _mem_split_block_done
  mov [r_si + ATTR_BLOCK_PREV], r_ax
_mem_split_block_done:
  pop r_si
  pop r_bx
  pop r_ax
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
mem_merge_free_block:
  ; input: block
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_bx
  push r_si
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx]
  test r_ax, r_ax
  jnz _mem_merge_free_block_done
_mem_merge_free_block_find_head:
  mov r_si, [r_bx + ATTR_BLOCK_PREV]
  cmp r_si, NO_MORE
  jz _mem_merge_free_block_do_merge
  mov r_ax, [r_si]
  test r_ax, r_ax
  jnz _mem_merge_free_block_do_merge
  mov r_bx, r_si
  jmp _mem_merge_free_block_find_head
_mem_merge_free_block_do_merge:
  mov r_si, [r_bx + ATTR_BLOCK_NEXT]
  cmp r_si, NO_MORE
  jz _mem_merge_free_block_done
  mov r_ax, [r_si]
  test r_ax, r_ax
  jnz _mem_merge_free_block_done
  mov r_ax, [r_bx + ATTR_BLOCK_SIZE]
  add r_ax, [r_si + ATTR_BLOCK_SIZE]
  add r_ax, BLOCK_STRUCT_SIZE
  mov [r_bx + ATTR_BLOCK_SIZE], r_ax
  mov r_ax, [r_si + ATTR_BLOCK_NEXT]
  mov [r_bx + ATTR_BLOCK_NEXT], r_ax
  mov r_si, r_ax
  mov [r_si + ATTR_BLOCK_PREV], r_bx
  mov r_ax, [FREE_BLOCK_SIZE]
  add r_ax, BLOCK_STRUCT_SIZE
  mov [FREE_BLOCK_SIZE], r_ax
  jmp _mem_merge_free_block_do_merge
_mem_merge_free_block_done:
  pop r_si
  pop r_bx
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
mem_alloc:
  ; input: size; output: ax=address
  push r_bp
  mov r_bp, r_sp
  push r_bx
  mov r_ax, [r_bp + ARGUMENT1]
  test r_ax, 1
  jz _mem_alloc_size_aligned
  inc r_ax
  mov [r_bp + ARGUMENT1], r_ax
_mem_alloc_size_aligned:
  push r_ax
  call mem_find_free_block
  cmp r_ax, NO_MORE
  jz _mem_alloc_done
  mov r_bx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  push r_bx
  call mem_split_block
  mov r_ax, 1
  mov [r_bx + ATTR_BLOCK_FLAG], r_ax
  mov r_ax, [r_bx + ATTR_BLOCK_SIZE]
  add r_ax, [USED_BLOCK_SIZE]
  mov [USED_BLOCK_SIZE], r_ax
  mov r_ax, [FREE_BLOCK_SIZE]
  sub r_ax, [r_bx + ATTR_BLOCK_SIZE]
  mov [FREE_BLOCK_SIZE], r_ax
  mov r_ax, r_bx
_mem_alloc_done:
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
mem_dealloc:
  ; input: block
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_cx
  push r_bx
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_cx, [r_bx + ATTR_BLOCK_SIZE]
  mov r_ax, [r_bx + ATTR_BLOCK_FLAG]
  test r_ax, r_ax
  jz _mem_dealloc_done
  xor r_ax, r_ax
  mov [r_bx + ATTR_BLOCK_FLAG], r_ax
  push r_bx
  call mem_merge_free_block
  mov r_ax, [FREE_BLOCK_SIZE]
  add r_ax, r_cx
  mov [FREE_BLOCK_SIZE], r_ax
_mem_dealloc_done:
  pop r_bx
  pop r_cx
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
get_free_block_size:
  mov r_ax, [FREE_BLOCK_SIZE]
  ret
  
  
get_used_block_size:
  mov r_ax, [USED_BLOCK_SIZE]
  ret
  
  
mem_get_data_offset:
  ; input: block; output: ax
  push r_bp
  mov r_bp, r_sp
  mov r_ax, [r_bp + ARGUMENT1]
  cmp r_ax, NO_MORE
  jz _mem_get_data_offset_done
  add r_ax, BLOCK_STRUCT_SIZE
_mem_get_data_offset_done:
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
mem_get_container_block:
  ; input object; output: ax
  push r_bp
  mov r_bp, r_sp
  mov r_ax, [r_bp + ARGUMENT1]
  sub r_ax, BLOCK_STRUCT_SIZE
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
mem_copy:
  ; input: source, dest, length
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_cx
  push r_si
  push r_di
  push es
  push ds
  pop es
  mov r_si, [r_bp + ARGUMENT1]
  mov r_di, [r_bp + ARGUMENT2]
  mov r_cx, [r_bp + ARGUMENT3]
  test r_cx, r_cx
  jz _mem_copy_done
  cld
  cmp r_si, r_di
  jz _mem_copy_done
  jnc _mem_copy_start
  std
  mov r_ax, r_cx
  dec r_ax
  add r_si, r_ax
  add r_di, r_ax
_mem_copy_start:
  rep
  movsb
_mem_copy_done:
  pop es
  pop r_di
  pop r_si
  pop r_cx
  pop r_ax
  pop r_bp
  ret 3 * REG_BYTE_SIZE
  
  
mem_reverse:
  ; input: offset, length; output: none
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_cx
  push r_si
  push r_di
  mov r_cx, [r_bp + ARGUMENT2]
  mov r_si, [r_bp + ARGUMENT1]
  mov r_di, r_si
  add r_di, r_cx
  dec r_di
_mem_reverse_loop:
  mov al, [r_si]
  mov ah, [r_di]
  mov [r_di], al
  mov [r_si], ah
  inc r_si
  dec r_di
  cmp r_si, r_di
  jb _mem_reverse_loop
  pop r_di
  pop r_si
  pop r_cx
  pop r_ax
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
mem_resize:
  ; input: target_block, new_size; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_bx
  mov r_ax, [r_bp + ARGUMENT2]
  test r_ax, 1
  jz _mem_resize_new_size_aligned
  inc r_ax
  mov [r_bp + ATTR_BLOCK_NEXT], r_ax
_mem_resize_new_size_aligned:
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx + ATTR_BLOCK_SIZE]
  cmp r_ax, [r_bp + ARGUMENT2]
  jz _mem_resize_skip
  jc _mem_resize_expand
_mem_resize_shrink:
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call mem_split_block
  jmp _mem_resize_fail
_mem_resize_expand:
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call mem_alloc
  cmp r_ax, NO_MORE
  jz _mem_resize_fail
  push r_ax
  mov r_cx, [r_bx + ATTR_BLOCK_SIZE]
  push r_cx
  push r_ax
  call mem_get_data_offset
  push r_ax
  push r_bx
  call mem_get_data_offset
  push r_ax
  call mem_copy
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call mem_dealloc
  pop r_ax
  jmp _mem_resize_done
_mem_resize_skip:
_mem_resize_fail:
  mov r_ax, [r_bp + ARGUMENT1]
_mem_resize_done:
  pop r_bx
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
mem_expand_if_needed:
  ; input: target block, new size; output: old/new block address or NO_MORE
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_bx
  mov r_ax, [r_bp + ARGUMENT2]
  test r_ax, 1
  jz _mem_expand_if_needed_new_size_aligned
  inc r_ax
  mov [r_bp + ARGUMENT2], r_ax
_mem_expand_if_needed_new_size_aligned:
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx + ATTR_BLOCK_SIZE]
  cmp r_ax, [r_bp + ARGUMENT2]
  jnc _mem_expand_if_needed_skip
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call mem_alloc
  cmp r_ax, NO_MORE
  jz _mem_expand_if_needed_fail
  push r_ax
  mov r_cx, [r_bx + ATTR_BLOCK_SIZE]
  push r_cx
  push r_ax
  call mem_get_data_offset
  push r_ax
  push r_bx
  call mem_get_data_offset
  push r_ax
  call mem_copy
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call mem_dealloc
  pop r_ax
  jmp _mem_expand_if_needed_done
_mem_expand_if_needed_skip:
_mem_expand_if_needed_fail:
  mov r_ax, [r_bp + ARGUMENT1]
_mem_expand_if_needed_done:
  pop r_bx
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
is_object:
  ; input: object; output: ZF=1 if object, else ZF=0
  push r_bp
  mov r_bp, r_sp
  push r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  test r_ax, 1
  jnz _is_object_done
  test r_ax, CLS_ID_NULL
  jz _is_object_false
  test r_ax, CLS_ID_TRUE
  jz _is_object_false
  test r_ax, CLS_ID_FALSE
  jnz _is_object_done
_is_object_false:
  or r_ax, 1
_is_object_done:
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
alloc_object:
  ; input: class id, instance variable count
  push r_bp
  mov r_bp, r_sp
  push r_bx
  mov r_ax, [r_bp + ARGUMENT2]
  add r_ax, 1
  shl r_ax, REG_SIZE_BITS
  push r_ax
  call mem_alloc
  cmp r_ax, NO_MORE
  jz _alloc_object_done
  push r_ax
  call mem_get_data_offset
  push r_ax
  mov r_bx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  mov [r_bx + ATTR_OBJ_CLASS_ID], r_ax
  pop r_ax
_alloc_object_done:
  pop r_bx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
increment_object_ref:
  ; input: object; output: none
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_si
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call mem_get_container_block
  mov r_si, r_ax
  mov r_ax, [r_si]
  cmp r_ax, MAX_REF_COUNT
  jz _increment_object_ref_done
  inc r_ax
  mov [r_si], r_ax
_increment_object_ref_done:
  pop r_si
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
decrement_object_ref:
  ; input: object; output: none
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_si
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call mem_get_container_block
  mov r_si, r_ax
  mov r_ax, [r_si]
  cmp r_ax, GARBAGE
  jz _decrement_object_ref_done
  dec r_ax
  test r_ax, r_ax
  jnz _decrement_object_ref_set_counter
  inc REG_SIZE_NAME [GARBAGE_COUNT]
  mov r_ax, GARBAGE
_decrement_object_ref_set_counter:
  mov [r_si], r_ax
_decrement_object_ref_done:
  pop r_si
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
destroy_object:
  ; input: object; output: nothing
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_cx
  push r_si
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call is_object
  jnz _destroy_object_done
  push r_ax
  call mem_get_container_block
  mov r_si, r_ax
  mov r_ax, [r_si + ATTR_BLOCK_SIZE]
  shr r_ax, 1
  dec r_ax
  test r_ax, r_ax
  jz _destroy_object_done
  mov r_cx, r_ax
  mov r_si, [r_bp + ARGUMENT1]
_destroy_object_destroy_child:
  add r_si, REG_BYTE_SIZE
  mov r_ax, [r_si]
  push r_ax
  call destroy_object
  loop _destroy_object_destroy_child
  mov r_si, [r_bp + ARGUMENT1]
  mov r_ax, GARBAGE
  cmp r_ax, [r_si]
  jz _destroy_object_done
  mov [r_si], r_ax
  inc REG_SIZE_NAME [GARBAGE_COUNT]
_destroy_object_done:
  pop r_si
  pop r_cx
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
mark_garbages:
  ; input: none; output: none
  push r_ax
  push r_bx
  mov r_bx, [FIRST_BLOCK]
_mark_garbages_check_block:
  mov r_ax, [r_bx]
  cmp r_ax, GARBAGE
  jnz _mark_garbages_object_destroyed
  push r_bx
  call destroy_object
_mark_garbages_object_destroyed:
  mov r_bx, [r_bx + ATTR_BLOCK_NEXT]
  cmp r_bx, NO_MORE
  jnz _mark_garbages_check_block
_mark_garbages_done:
  pop r_bx
  pop r_ax
  ret
  
  
collect_garbage:
  ; input: none; output: none
  push r_ax
  push r_bx
  push r_si
  call mark_garbages
  mov r_bx, [FIRST_BLOCK]
_collect_garbage_check_block:
  mov r_ax, [r_bx]
  cmp r_ax, GARBAGE
  jnz _collect_garbage_block_checked
  xor r_ax, r_ax
  mov [r_bx], r_ax
  mov r_si, r_bx
  mov r_ax, [r_si + ATTR_BLOCK_NEXT]
  cmp r_ax, NO_MORE
  jz _collect_garbage_next_block_found
  push r_si
  mov r_ax, [r_si]
  pop r_si
  test r_ax, r_ax
  jnz _collect_garbage_next_block_found
  mov r_si, r_ax
_collect_garbage_next_block_found:
  push r_bx
  call mem_dealloc
  mov r_bx, r_si
_collect_garbage_block_checked:
  mov r_bx, [r_bx + ATTR_BLOCK_NEXT]
  cmp r_bx, NO_MORE
  jnz _collect_garbage_check_block
  xor r_ax, r_ax
  mov [GARBAGE_COUNT], r_ax
_collect_garbage_done:
  pop r_si
  pop r_bx
  pop r_ax
  ret
  
  
collect_garbage_if_needed:
  push r_ax
  mov r_ax, [GARBAGE_COUNT]
  test r_ax, r_ax
  jz _collect_garbage_if_needed_skip
  push r_cx
  push r_dx
  call get_free_block_size
  mov r_cx, r_ax
  call get_used_block_size
  add r_cx, r_ax
  shr r_cx, 2
  cmp r_ax, r_cx
  jc _collect_garbage_if_needed_done
  call collect_garbage
_collect_garbage_if_needed_done:
  pop r_dx
  pop r_cx
_collect_garbage_if_needed_skip:
  pop r_ax
  ret
  
  
unassign_object:
  ; input: object; output: nothing
  push r_bp
  mov r_bp, r_sp
  push r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call is_object
  jnz _unassign_object_done
  push r_ax
  call decrement_object_ref
  call collect_garbage_if_needed
_unassign_object_done:
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
create_str:
  ; input: length; output: ax=str object or zero if fail
  push r_bp
  mov r_bp, r_sp
  push r_si
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call mem_alloc
  cmp r_ax, NO_MORE
  jnz _create_str_alloc_success
  mov r_ax, CLS_ID_NULL
  jmp _create_str_failed
_create_str_alloc_success:
  push r_ax
  call mem_get_data_offset
  mov r_si, r_ax                                ; si = data offset
  mov r_ax, 2                                  ; instance_variable count
  push r_ax
  mov r_ax, CLS_ID_STRING                      ; class_id
  push r_ax
  call alloc_object
  cmp r_ax, NO_MORE
  jz _create_str_failed
  xchg r_si, r_ax                               ; si = string object, ax = data offset
  mov [r_si + ATTR_OBJ_DATA_OFFSET], r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  mov [r_si + ATTR_STR_LENGTH], r_ax
  mov r_ax, r_si
_create_str_failed:
  pop r_si
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
load_str:
  ; input: offset; output: ax
  ; string structure:
  ; - class id
  ; - string length
  ; - buffer location
  push r_bp
  mov r_bp, r_sp
  push r_bx
  push r_si
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx]
  push r_ax
  call create_str
  cmp r_ax, CLS_ID_NULL
  jz _load_str_failed
  mov r_si, r_ax
  mov r_ax, [r_bx]
  push r_ax
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  mov r_ax, r_bx
  add r_ax, REG_BYTE_SIZE
  push r_ax
  call mem_copy
  mov r_ax, r_si
_load_str_failed:
  pop r_si
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
str_length:
  ; input: str; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_bx
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx + ATTR_STR_LENGTH]
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
str_copy:
  ; input str; output: ax
  ; create a copy of existing string
  push r_bp
  mov r_bp, r_sp
  push r_si
  push r_di
  mov r_si, [r_bp + ARGUMENT1]
  mov r_ax, [r_si + ATTR_STR_LENGTH]
  push r_ax
  call create_str
  cmp r_ax, CLS_ID_NULL
  jz _str_copy_failed
  mov r_di, r_ax
  mov r_ax, [r_si + ATTR_STR_LENGTH]
  push r_ax
  mov r_ax, [r_di + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  call mem_copy
  mov r_ax, r_di
_str_copy_failed:
  pop r_di
  pop r_si
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
str_expand:
  ; input: str, append_size; output: CF set if failed
  ; copy str length first before calling this function
  ; because it may changed
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_cx
  push r_bx
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  mov r_bx, [r_si + ATTR_OBJ_DATA_OFFSET]
  mov r_cx, [r_bp + ARGUMENT2]
  test r_cx, r_cx
  jz _str_expand_success
  add r_cx, [r_si + ATTR_STR_LENGTH]
  cmp r_cx, [r_bx - BLOCK_STRUCT_SIZE + ATTR_BLOCK_SIZE]
  jnc _str_expand_update_size
  mov r_ax, r_cx
  shr r_ax, 1
  add r_ax, r_cx
  push r_ax
  call mem_alloc
  cmp r_ax, CLS_ID_NULL
  jz _str_expand_failed
  push r_ax
  call mem_get_data_offset
  mov r_bx, r_ax
  mov r_ax, [r_si + ATTR_STR_LENGTH]
  push r_ax
  push r_bx
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  call mem_copy
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  sub r_ax, BLOCK_STRUCT_SIZE
  push r_ax
  call mem_dealloc
  mov [r_si + ATTR_OBJ_DATA_OFFSET], r_bx
_str_expand_update_size:
  mov [r_si + ATTR_STR_LENGTH], r_cx
_str_expand_success:
  clc
  jmp _str_expand_done
_str_expand_failed:
  stc
_str_expand_done:
  pop r_si
  pop r_bx
  pop r_cx
  pop r_ax
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
str_concat:
  ; input: str1, str2; output: ax=new str or zero if fail
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_bx
  push r_si
  push r_di
  mov r_si, [r_bp + ARGUMENT1]
  mov r_di, [r_bp + ARGUMENT2]
  mov r_cx, [r_si + ATTR_STR_LENGTH]
  add r_cx, [r_di + ATTR_STR_LENGTH]
  push r_cx
  call create_str
  cmp r_ax, CLS_ID_NULL
  jz _str_concat_failed
  mov r_bx, r_ax
  mov r_ax, [r_si + ATTR_STR_LENGTH]
  push r_ax
  mov r_ax, [r_bx + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  call mem_copy
  mov r_ax, [r_di + ATTR_STR_LENGTH]
  push r_ax
  mov r_ax, [r_bx + ATTR_OBJ_DATA_OFFSET]
  add r_ax, [r_si + ATTR_STR_LENGTH]
  push r_ax
  mov r_ax, [r_di + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  call mem_copy
  mov r_ax, r_bx
_str_concat_failed:
  pop r_di
  pop r_si
  pop r_bx
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
str_substr:
  ; input: str, offset, size; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_si
  push r_di
  mov r_ax, [r_bp + ARGUMENT3]
  push r_ax
  call create_str
  cmp r_ax, CLS_ID_NULL
  jz _str_substr_failed
  mov r_di, r_ax
  mov r_si, [r_bp + ARGUMENT1]
  mov r_ax, [r_bp + ARGUMENT3]
  push r_ax
  mov r_ax, [r_di + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  add r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call mem_copy
  mov r_ax, r_di
_str_substr_failed:
  pop r_di
  pop r_si
  pop r_bp
  ret 3 * REG_BYTE_SIZE
  
  
str_lcase:
  ; input: str; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_bx
  push r_si
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call str_copy
  cmp r_ax, CLS_ID_NULL
  jz _str_lcase_done
  mov r_bx, r_ax
  mov r_cx, [r_bx +  ATTR_STR_LENGTH]
  test r_cx, r_cx
  jz _str_lcase_processed
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
_str_lcase_loop:
  mov al, [r_si]
  cmp al, 41h
  jc _str_lcase_skip_char
  cmp al, 5ah
  jg _str_lcase_skip_char
  add al, 20h
  mov [r_si], al
_str_lcase_skip_char:
  inc r_si
  loop _str_lcase_loop
_str_lcase_processed:
  mov r_ax, r_bx
_str_lcase_done:
  pop r_si
  pop r_bx
  pop r_cx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
str_ucase:
  ; input: str; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_bx
  push r_si
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call str_copy
  cmp r_ax, CLS_ID_NULL
  jz _str_ucase_done
  mov r_bx, r_ax
  mov r_cx, [r_bx +  ATTR_STR_LENGTH]
  test r_cx, r_cx
  jz _str_ucase_processsed
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
_str_ucase_loop:
  mov al, [r_si]
  cmp al, 61h
  jc _str_ucase_skip_char
  cmp al, 7ah
  jg _str_ucase_skip_char
  sub al, 20h
  mov [r_si], al
_str_ucase_skip_char:
  inc r_si
  loop _str_ucase_loop
_str_ucase_processsed:
  mov r_ax, r_bx
_str_ucase_done:
  pop r_si
  pop r_bx
  pop r_cx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
str_append:
  ; input: dst, src; output: CF set if failed
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_cx
  push r_bx
  push r_si
  push r_di
  mov r_si, [r_bp + ARGUMENT1]
  mov r_di, [r_bp + ARGUMENT2]
  mov r_cx, [r_si + ATTR_STR_LENGTH]
  mov r_ax, [r_di + ATTR_STR_LENGTH]
  push r_ax
  push r_si
  call str_expand
  jc _str_append_failed
  mov r_ax, [r_di + ATTR_STR_LENGTH]
  push r_ax
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  add r_ax, r_cx
  push r_ax
  mov r_ax, [r_di + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  call mem_copy
_str_append_success:
  clc
  jmp _str_append_done
_str_append_failed:
  stc
_str_append_done:
  pop r_di
  pop r_si
  pop r_bx
  pop r_cx
  pop r_ax
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
str_append_chr:
  ; input: str, chr; output: CF set if failed
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_bx
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  mov r_ax, [r_bp + ARGUMENT2]
  push dword 1
  push r_si
  call str_expand
  jc _str_append_chr_failed
  mov r_bx, [r_si + ATTR_OBJ_DATA_OFFSET]
  add r_bx, [r_si + ATTR_STR_LENGTH]
  mov [r_bx - 1], al
_str_append_chr_success:
  clc
  jmp _str_append_chr_done
_str_append_chr_failed:
  stc
_str_append_chr_done:
  pop r_si
  pop r_bx
  pop r_ax
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
str_reverse:
  ; input: str object; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_bx
  push r_si
  push r_di
  mov r_si, [r_bp + ARGUMENT1]
  mov r_ax, [r_si + ATTR_STR_LENGTH]
  push r_ax
  call create_str
  mov r_bx, r_ax
  mov r_cx, [r_si + ATTR_STR_LENGTH]
  test r_cx, r_cx
  jz _str_reverse_done
  mov r_ax, [r_si + ATTR_OBJ_DATA_OFFSET]
  add r_ax, r_cx
  dec r_ax
  mov r_si, r_ax
  mov r_di, [r_bx + ATTR_OBJ_DATA_OFFSET]
_str_reverse_copy:
  mov al, [r_si]
  mov [r_di], al
  dec r_si
  inc r_di
  loop _str_reverse_copy
_str_reverse_done:
  mov r_ax, r_bx
  pop r_di
  pop r_si
  pop r_bx
  pop r_cx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
; ;str_strip:
; ;str_truncate:
; ;str_shift:
; ;str_prepend:
; ;str_insert:
  
  
_cbw:
  ; input: value; output: ax
  push r_bp
  mov r_bp, r_sp
  mov r_ax, [r_bp + 4]
  cbw
  cwd
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
_cwb:
  ; input: value; output: ax
  push r_bp
  mov r_bp, r_sp
  mov r_ax, [r_bp + 4]
  and eax, 0xff
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
get_byte_at:
  ; input: offset, index; output: al
  push r_bp
  mov r_bp, r_sp
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  add r_si, [r_bp + ARGUMENT2]
  mov al, [r_si]
  pop r_si
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
set_byte_at:
  ; input: offset, index, value
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  add r_si, [r_bp + ARGUMENT2]
  mov r_ax, [r_bp + ARGUMENT3]
  mov [r_si], al
  pop r_si
  pop r_ax
  pop r_bp
  ret 3 * REG_BYTE_SIZE
  
  
get_word_at:
  ; input: offset, index; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  add r_si, [r_bp + ARGUMENT2]
  mov r_ax, [r_si]
  pop r_si
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
set_word_at:
  ; input: offset, index, value
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  add r_si, [r_bp + ARGUMENT2]
  mov r_ax, [r_bp + ARGUMENT3]
  mov [r_si], r_ax
  pop r_si
  pop r_ax
  pop r_bp
  ret 3 * REG_BYTE_SIZE
  
  
int_pack:
  ; input: value; output: ax
  push r_bp
  mov r_bp, r_sp
  mov r_ax, [r_bp + ARGUMENT1]
  shl r_ax, 1
  or r_ax, 1
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
int_unpack:
  ; input: value; output: ax
  push r_bp
  mov r_bp, r_sp
  mov r_ax, [r_bp + ARGUMENT1]
  shr r_ax, 1
  test r_ax, INT_MIN_MASK2
  jz _int_unpack_done
  or r_ax, INT_MIN_MASK1
_int_unpack_done:
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
int_add:
  ; input: v1, v2; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  mov r_cx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call int_unpack
  add r_ax, r_cx
  push r_ax
  call int_pack
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
int_subtract:
  ; input: v1, v2; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  mov r_cx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call int_unpack
  sub r_ax, r_cx
  push r_ax
  call int_pack
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
int_multiply:
  ; input: v1, v2; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_dx
  xor r_dx, r_dx
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  mov r_cx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call int_unpack
  imul r_cx
  push r_ax
  call int_pack
  pop r_dx
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
int_divide:
  ; input: v1, v2; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_dx
  xor r_dx, r_dx
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  mov r_cx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call int_unpack
  idiv r_cx
  push r_ax
  call int_pack
  pop r_dx
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
int_and:
  ; input: v1, v2; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  mov r_cx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call int_unpack
  and r_ax, r_cx
  push r_ax
  call int_pack
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
int_or:
  ; input: v1, v2; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  mov r_cx, r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call int_unpack
  or r_ax, r_cx
  push r_ax
  call int_pack
  pop r_cx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
nible_to_h:
  ; input: al; output: al
  and al, 0fh
  add al, 30h
  cmp al, 3ah
  jc _nible_to_h_done
  add al, 7
_nible_to_h_done:
  ret
  
  
byte_to_h:
  ; input: al; output: ax
  mov ah, al
  call nible_to_h
  xchg ah, al
  shr al, 4
  call nible_to_h
  xchg ah, al
  ret
  
  
int_to_h8:
  ; input: int; output: r_ax
  push r_bp
  mov r_bp, r_sp
  push r_bx
  push r_si
  push REG_SIZE_NAME 2
  call create_str
  mov r_bx, r_ax
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
  mov r_ax, [r_bp + ARGUMENT1]
  call byte_to_h
  xchg ah, al
  mov [r_si], ax
  mov r_ax, r_bx
  pop r_si
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
int_to_h16:
  ; input: int; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_bx
  push r_si
  push REG_SIZE_NAME 4
  call create_str
  mov r_bx, r_ax
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call byte_to_h
  xchg ah, al
  mov [r_si + 2], ax
  pop r_ax
  xchg ah, al
  call byte_to_h
  xchg ah, al
  mov [r_si + 0], ax
  mov r_ax, r_bx
  pop r_si
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
int_to_s:
  ; input: int; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_cx
  push r_dx
  push r_bx
  push r_di
  push REG_SIZE_NAME 6
  call create_str
  mov r_bx, r_ax
  xor r_ax, r_ax
  mov [r_bx + ATTR_STR_LENGTH], r_ax
  mov r_di, [r_bx + ATTR_OBJ_DATA_OFFSET]
  mov r_ax, [r_bp + ARGUMENT1]
  mov r_cx, 10
_int_to_s_loop:
  xor r_dx, r_dx
  div cx
  push r_ax
  mov al, dl
  call nible_to_h
  mov [r_di], al
  inc r_di
  inc REG_SIZE_NAME [r_bx + ATTR_STR_LENGTH]
  pop r_ax
  test r_ax, r_ax
  jnz _int_to_s_loop
  mov r_ax, [r_bx + ATTR_STR_LENGTH]
  push r_ax
  mov r_ax, [r_bx + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  call mem_reverse
  mov r_ax, r_bx
  pop r_di
  pop r_bx
  pop r_dx
  pop r_cx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
int_to_chr:
  ; input: int; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_bx
  push r_si
  push REG_SIZE_NAME 2
  call create_str
  mov r_bx, r_ax
  mov r_ax, 1
  mov [r_bx + ATTR_STR_LENGTH], r_ax
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
  mov r_ax, [r_bp + ARGUMENT1]
  push r_ax
  call int_unpack
  mov [r_si], al
  mov r_ax, r_bx
  pop r_si
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
is_true:
  ; input: object; output: ZF
  push r_bp
  mov r_bp, r_sp
  push r_ax
  mov r_ax, [r_bp + ARGUMENT1]
  cmp r_ax, CLS_ID_TRUE
  jz _is_true_done
  cmp r_ax, CLS_ID_FALSE
  jz _is_true_false
  test r_ax, r_ax
  jmp _is_true_done
_is_true_false:
  or r_ax, 1
_is_true_done:
  pop r_ax
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
int_compare:
  ; should be called from compare function
  ; input: main caller, object1, object2; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_si
  push r_di
  mov r_si, [r_bp + ARGUMENT2]
  mov r_di, [r_bp + ARGUMENT3]
  push r_si
  call is_object
  jz _int_compare_false
  push r_di
  call is_object
  jz _int_compare_false
  mov r_ax, _int_compare_done
  add r_ax, CODE_BASE_ADDRESS
  push r_ax
  mov r_ax, [r_bp + REG_BYTE_SIZE]
  push r_ax
  mov r_ax, CLS_ID_TRUE
  cmp r_si, r_di
  ret
_int_compare_false:
  mov r_ax, CLS_ID_FALSE
_int_compare_done:
  pop r_di
  pop r_si
  pop r_bp
  add r_sp, REG_BYTE_SIZE
  ret 2 * REG_BYTE_SIZE
  
  
is_equal:
  ; input: object1, object2; output: ax
  call int_compare
  jz _is_equal_done
  mov r_ax, CLS_ID_FALSE
_is_equal_done:
  ret
  
  
is_not_equal:
  ; input: object1, object2; output: ax
  call int_compare
  jnz _is_not_equal_done
  mov r_ax, CLS_ID_FALSE
_is_not_equal_done:
  ret
  
  
is_less_than:
  ; input: object1, object2; output: ax
  call int_compare
  jl _is_less_than_done
  mov r_ax, CLS_ID_FALSE
_is_less_than_done:
  ret
  
  
is_less_than_or_equal:
  ; input: object1, object2; output: ax
  call int_compare
  jle _is_less_than_or_equal_done
  mov r_ax, CLS_ID_FALSE
_is_less_than_or_equal_done:
  ret
  
  
is_greater_than:
  ; input: object1, object2; output: ax
  call int_compare
  jg _is_greater_done
  mov r_ax, CLS_ID_FALSE
_is_greater_done:
  ret
  
  
is_greater_than_or_equal:
  ; input: object1, object2; output: ax
  call int_compare
  jge _is_greater_than_or_equal_done
  mov r_ax, CLS_ID_FALSE
_is_greater_than_or_equal_done:
  ret
  
  
create_array:
  ; creates empty array
  ; input: none; output: array object
  push r_bx
  push r_si
  xor r_ax, r_ax
  push r_ax
  call mem_alloc
  cmp r_ax, NO_MORE
  jz _create_array_done
  push r_ax
  call mem_get_data_offset
  mov r_si, r_ax
  mov r_ax, 2                                 ; iv count: length, data offset
  push r_ax
  mov r_ax, CLS_ID_ARRAY
  push r_ax
  call alloc_object
  cmp r_ax, NO_MORE
  jz _create_array_done
  mov r_bx, r_ax
  xor r_ax, r_ax
  push r_ax
  call int_pack
  mov [r_bx + ATTR_ARY_LENGTH], r_ax          ; element count
  mov [r_bx + ATTR_OBJ_DATA_OFFSET], r_si     ; data offset
  mov r_ax, r_bx
_create_array_done:
  pop r_si
  pop r_bx
  ret
  
  
array_length:
  ; input: array; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_bx
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx + ATTR_ARY_LENGTH]
  pop r_bx
  pop r_bp
  ret 1 * REG_BYTE_SIZE
  
  
array_get_item:
  ; input: array, index; output: ax
  push r_bp
  mov r_bp, r_sp
  push r_bx
  push r_si
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  shl r_ax, REG_SIZE_BITS
  add r_si, r_ax
  mov r_ax, [r_si]
  pop r_si
  pop r_bx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
array_set_item:
  ; input: array, index, value
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_bx
  push r_si
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
  mov r_ax, [r_bp + ARGUMENT2]
  push r_ax
  call int_unpack
  shl r_ax, REG_SIZE_BITS
  add r_si, r_ax
  mov r_ax, [r_bp + ARGUMENT3]
  mov [r_si], r_ax
  pop r_si
  pop r_bx
  pop r_ax
  pop r_bp
  ret 3 * REG_BYTE_SIZE
  
  
array_append:
  ; input: array, value; output: array object
  push r_bp
  mov r_bp, r_sp
  push r_bx
  push r_si
  mov r_bx, [r_bp + ARGUMENT1]
  mov r_ax, [r_bx + ATTR_ARY_LENGTH]
  push r_ax
  call int_unpack
  inc r_ax
  shl r_ax, REG_SIZE_BITS
  push r_ax
  mov r_ax, [r_bx + ATTR_OBJ_DATA_OFFSET]
  push r_ax
  call mem_get_container_block
  push r_ax
  call mem_expand_if_needed
  cmp r_ax, NO_MORE
  jz _array_append_failed
  push r_ax
  call mem_get_data_offset
  cmp r_ax, [r_bx + ATTR_OBJ_DATA_OFFSET]
  jz _array_append_block_relocated
  mov [r_bx + ATTR_OBJ_DATA_OFFSET], r_ax
_array_append_block_relocated:
  mov r_si, [r_bx + ATTR_OBJ_DATA_OFFSET]
  mov r_ax, [r_bx + ATTR_ARY_LENGTH]
  push r_ax
  call int_unpack
  shl r_ax, REG_SIZE_BITS
  add r_si, r_ax
  mov r_ax, [r_bp + ARGUMENT2]
  mov [r_si], r_ax
  mov r_ax, [r_bx + ATTR_ARY_LENGTH]
  push r_ax
  call int_unpack
  inc r_ax
  push r_ax
  call int_pack
  mov [r_bx + ATTR_ARY_LENGTH], r_ax
_array_append_failed:
  mov r_ax, r_bx
  pop r_si
  pop r_bx
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
get_obj_var:
  ; input: object, var-index
  push r_bp
  mov r_bp, r_sp
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  mov r_ax, [r_bp + ARGUMENT2]
  add r_ax, 1
  shl r_ax, REG_SIZE_BITS
  add r_si, r_ax
  mov r_ax, [r_si]
  pop r_si
  pop r_bp
  ret 2 * REG_BYTE_SIZE
  
  
set_obj_var:
  ; input: object, var-index, value
  push r_bp
  mov r_bp, r_sp
  push r_ax
  push r_si
  mov r_si, [r_bp + ARGUMENT1]
  mov r_ax, [r_bp + ARGUMENT2]
  add r_ax, 1
  shl r_ax, REG_SIZE_BITS
  add r_si, r_ax
  push r_si
  call unassign_object
  mov r_ax, [r_bp + ARGUMENT3]
  mov [r_si], r_ax
  pop r_si
  pop r_ax
  pop r_bp
  ret 3 * REG_BYTE_SIZE
  
  
puts:
  ; input: str object
  ; jmp print
  ret 1 * REG_BYTE_SIZE
