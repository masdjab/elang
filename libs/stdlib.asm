dw table
dw 7 dup 0

include 'stdproc.asm'

table:
dw _pass_arguments
  db "_pass_arguments", 0
dw _set_result
  db "_set_result", 0
dw _mem_block_init
  db "_mem_block_init", 0
dw mem_find_free_block
  db "mem_find_free_block", 0
dw mem_split_block
  db "mem_split_block", 0
dw mem_merge_free_block
  db "mem_merge_free_block", 0
dw _mem_alloc
  db "_mem_alloc", 0
dw _mem_dealloc
  db "_mem_dealloc", 0
dw _get_free_block_size
  db "_get_free_block_size", 0
dw _get_used_block_size
  db "_get_used_block_size", 0
dw _mem_get_data_offset
  db "_mem_get_data_offset", 0
dw _mem_get_container_block
  db "_mem_get_container_block", 0
dw _mem_expand_if_needed
  db "_mem_expand_if_needed", 0
dw mem_copy
  db "mem_copy", 0
dw mem_reverse
  db "mem_reverse", 0
dw mem_resize
  db "mem_resize", 0
dw _is_object
  db "_is_object", 0
dw _alloc_object
  db "_alloc_object", 0
dw _increment_object_ref
  db "_increment_object_ref", 0
dw _decrement_object_ref
  db "_decrement_object_ref", 0
dw _destroy_object
  db "_destroy_object", 0
dw _mark_garbages
  db "_mark_garbages", 0
dw _collect_garbage
  db "_collect_garbage", 0
dw _collect_garbage_if_needed
  db "_collect_garbage_if_needed", 0
dw _unassign_object
  db "_unassign_object", 0
dw create_str
  db "create_str", 0
dw _load_str
  db "_load_str", 0
dw _str_length
  db "_str_length", 0
dw _str_copy
  db "_str_copy", 0
dw _str_concat
  db "_str_concat", 0
dw _str_substr
  db "_str_substr", 0
dw _str_lcase
  db "_str_lcase", 0
dw _str_ucase
  db "_str_ucase", 0
dw _str_append
  db "_str_append", 0
dw _str_reverse
  db "_str_reverse", 0
dw _cbw
  db "_cbw", 0
dw _cwb
  db "_cwb", 0
dw _get_byte_at
  db "_get_byte_at", 0
dw _set_byte_at
  db "_set_byte_at", 0
dw _get_word_at
  db "_get_word_at", 0
dw _set_word_at
  db "_set_word_at", 0
dw _int_pack
  db "_int_pack", 0
dw _int_unpack
  db "_int_unpack", 0
dw _int_add
  db "_int_add", 0
dw _int_subtract
  db "_int_subtract", 0
dw _int_multiply
  db "_int_multiply", 0
dw _int_divide
  db "_int_divide", 0
dw _int_and
  db "_int_and", 0
dw _int_or
  db "_int_or", 0
dw _nible_to_h
  db "_nible_to_h", 0
dw _byte_to_h
  db "_byte_to_h", 0
dw _int_to_h8
  db "_int_to_h8", 0
dw _int_to_h16
  db "_int_to_h16", 0
dw _int_to_s
  db "_int_to_s", 0
dw _int_to_chr
  db "_int_to_chr", 0
dw _is_true
  db "_is_true", 0
dw _is_equal
  db "_is_equal", 0
dw _is_not_equal
  db "_is_not_equal", 0
dw _is_less_than
  db "_is_less_than", 0
dw _is_less_than_or_equal
  db "_is_less_than_or_equal", 0
dw _is_greater_than
  db "_is_greater_than", 0
dw _is_greater_than_or_equal
  db "_is_greater_than_or_equal", 0
dw _create_array
  db "_create_array", 0
dw _array_length
  db "_array_length", 0
dw _array_get_item
  db "_array_get_item", 0
dw _array_set_item
  db "_array_set_item", 0
dw _array_append
  db "_array_append", 0
dw _get_obj_var
  db "_get_obj_var", 0
dw _set_obj_var
  db "_set_obj_var", 0
dw _putchr
  db "_putchr", 0
dw _putline
  db "_putline", 0
dw _putstr
  db "_putstr", 0
dw _print
  db "print", 0
dw _puts
  db "puts", 0
dw _getch
  db "_getch", 0
dw _read_sector
  db "_read_sector", 0
dw _write_sector
  db "_write_sector", 0
