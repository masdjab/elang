table:
var pass_arguments
  db "_pass_arguments", 0
var set_result
  db "_set_result", 0
var mem_block_init
  db "_mem_block_init", 0
var mem_find_free_block
  db "mem_find_free_block", 0
var mem_split_block
  db "mem_split_block", 0
var mem_merge_free_block
  db "mem_merge_free_block", 0
var mem_alloc
  db "_mem_alloc", 0
var mem_dealloc
  db "_mem_dealloc", 0
var get_free_block_size
  db "_get_free_block_size", 0
var get_used_block_size
  db "_get_used_block_size", 0
var mem_get_data_offset
  db "_mem_get_data_offset", 0
var mem_get_container_block
  db "_mem_get_container_block", 0
var mem_expand_if_needed
  db "_mem_expand_if_needed", 0
var mem_copy
  db "mem_copy", 0
var mem_reverse
  db "mem_reverse", 0
var mem_resize
  db "mem_resize", 0
var is_object
  db "_is_object", 0
var alloc_object
  db "_alloc_object", 0
var increment_object_ref
  db "_increment_object_ref", 0
var decrement_object_ref
  db "_decrement_object_ref", 0
var destroy_object
  db "_destroy_object", 0
var mark_garbages
  db "_mark_garbages", 0
var collect_garbage
  db "_collect_garbage", 0
var collect_garbage_if_needed
  db "_collect_garbage_if_needed", 0
var unassign_object
  db "_unassign_object", 0
var create_str
  db "create_str", 0
var load_str
  db "_load_str", 0
var str_length
  db "_str_length", 0
var str_copy
  db "_str_copy", 0
var str_concat
  db "_str_concat", 0
var str_substr
  db "_str_substr", 0
var str_lcase
  db "_str_lcase", 0
var str_ucase
  db "_str_ucase", 0
var str_append
  db "_str_append", 0
var str_reverse
  db "_str_reverse", 0
var _cbw
  db "_cbw", 0
var _cwb
  db "_cwb", 0
var get_byte_at
  db "_get_byte_at", 0
var set_byte_at
  db "_set_byte_at", 0
var get_word_at
  db "_get_word_at", 0
var set_word_at
  db "_set_word_at", 0
var int_pack
  db "_int_pack", 0
var int_unpack
  db "_int_unpack", 0
var int_add
  db "_int_add", 0
var int_subtract
  db "_int_subtract", 0
var int_multiply
  db "_int_multiply", 0
var int_divide
  db "_int_divide", 0
var int_and
  db "_int_and", 0
var int_or
  db "_int_or", 0
var nible_to_h
  db "_nible_to_h", 0
var byte_to_h
  db "_byte_to_h", 0
var int_to_h8
  db "_int_to_h8", 0
var int_to_h16
  db "_int_to_h16", 0
var int_to_s
  db "_int_to_s", 0
var int_to_chr
  db "_int_to_chr", 0
var is_true
  db "_is_true", 0
var is_equal
  db "_is_equal", 0
var is_not_equal
  db "_is_not_equal", 0
var is_less_than
  db "_is_less_than", 0
var is_less_than_or_equal
  db "_is_less_than_or_equal", 0
var is_greater_than
  db "_is_greater_than", 0
var is_greater_than_or_equal
  db "_is_greater_than_or_equal", 0
var create_array
  db "_create_array", 0
var array_length
  db "_array_length", 0
var array_get_item
  db "_array_get_item", 0
var array_set_item
  db "_array_set_item", 0
var array_append
  db "_array_append", 0
var get_obj_var
  db "_get_obj_var", 0
var set_obj_var
  db "_set_obj_var", 0
;var print
;  db "print", 0
var puts
  db "puts", 0
;var getch
;  db "_getch", 0
