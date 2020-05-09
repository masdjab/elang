include 'fasm32.asm'

INT_MIN_MASK1             EQU 80000000h
INT_MIN_MASK2             EQU 40000000h

macro var [varargs] {dd varargs}

dw 2
dw table
dw 7 dup 0

include 'stdproc.asm'
include 'dados.asm'


table:
var pass_arguments
db 0x10, 0x80, 0, 0, "_pass_arguments", 0
db 0x15, 0x80, 0, 0, "_set_result", 0
db 0x1a, 0x80, 0, 0, "_mem_block_init", 0
db 0x1f, 0x80, 0, 0, "mem_find_free_block", 0
db 0x24, 0x80, 0, 0, "mem_split_block", 0
db 0x29, 0x80, 0, 0, "mem_merge_free_block", 0
db 0x2e, 0x80, 0, 0, "_mem_alloc", 0
db 0x33, 0x80, 0, 0, "_mem_dealloc", 0
db 0x38, 0x80, 0, 0, "_get_free_block_size", 0
db 0x3d, 0x80, 0, 0, "_get_used_block_size", 0
db 0x42, 0x80, 0, 0, "_mem_get_data_offset", 0
db 0x47, 0x80, 0, 0, "_mem_get_container_block", 0
db 0x4c, 0x80, 0, 0, "_mem_expand_if_needed", 0
db 0x51, 0x80, 0, 0, "mem_copy", 0
db 0x56, 0x80, 0, 0, "mem_reverse", 0
db 0x5b, 0x80, 0, 0, "mem_resize", 0
db 0x60, 0x80, 0, 0, "_is_object", 0
db 0x65, 0x80, 0, 0, "_alloc_object", 0
db 0x6a, 0x80, 0, 0, "_increment_object_ref", 0
db 0x6f, 0x80, 0, 0, "_decrement_object_ref", 0
db 0x74, 0x80, 0, 0, "_destroy_object", 0
db 0x79, 0x80, 0, 0, "_mark_garbages", 0
db 0x7e, 0x80, 0, 0, "_collect_garbage", 0
db 0x83, 0x80, 0, 0, "_collect_garbage_if_needed", 0
db 0x88, 0x80, 0, 0, "_unassign_object", 0
db 0x8d, 0x80, 0, 0, "create_str", 0
db 0x92, 0x80, 0, 0, "_load_str", 0
db 0x97, 0x80, 0, 0, "_str_length", 0
db 0x9c, 0x80, 0, 0, "_str_copy", 0
db 0xa1, 0x80, 0, 0, "_str_concat", 0
db 0xa6, 0x80, 0, 0, "_str_substr", 0
db 0xab, 0x80, 0, 0, "_str_lcase", 0
db 0xb0, 0x80, 0, 0, "_str_ucase", 0
db 0xb5, 0x80, 0, 0, "_str_append", 0
db 0xba, 0x80, 0, 0, "_str_reverse", 0
db 0xbf, 0x80, 0, 0, "_cbw", 0
db 0xc4, 0x80, 0, 0, "_cwb", 0
db 0xc9, 0x80, 0, 0, "_get_byte_at", 0
db 0xce, 0x80, 0, 0, "_set_byte_at", 0
db 0xd3, 0x80, 0, 0, "_get_word_at", 0
db 0xd8, 0x80, 0, 0, "_set_word_at", 0
db 0xdd, 0x80, 0, 0, "_int_pack", 0
db 0xe2, 0x80, 0, 0, "_int_unpack", 0
db 0xe7, 0x80, 0, 0, "_int_add", 0
db 0xec, 0x80, 0, 0, "_int_subtract", 0
db 0xf1, 0x80, 0, 0, "_int_multiply", 0
db 0xf6, 0x80, 0, 0, "_int_divide", 0
db 0xfb, 0x80, 0, 0, "_int_and", 0
db 0x00, 0x81, 0, 0, "_int_or", 0
db 0x05, 0x81, 0, 0, "_nible_to_h", 0
db 0x0a, 0x81, 0, 0, "_byte_to_h", 0
db 0x0f, 0x81, 0, 0, "_int_to_h8", 0
db 0x14, 0x81, 0, 0, "_int_to_h16", 0
db 0x19, 0x81, 0, 0, "_int_to_s", 0
db 0x1e, 0x81, 0, 0, "_int_to_chr", 0
db 0x23, 0x81, 0, 0, "_is_true", 0
db 0x28, 0x81, 0, 0, "_is_equal", 0
db 0x2d, 0x81, 0, 0, "_is_not_equal", 0
db 0x32, 0x81, 0, 0, "_is_less_than", 0
db 0x37, 0x81, 0, 0, "_is_less_than_or_equal", 0
db 0x3c, 0x81, 0, 0, "_is_greater_than", 0
db 0x41, 0x81, 0, 0, "_is_greater_than_or_equal", 0
db 0x46, 0x81, 0, 0, "_create_array", 0
db 0x4b, 0x81, 0, 0, "_array_length", 0
db 0x50, 0x81, 0, 0, "_array_get_item", 0
db 0x55, 0x81, 0, 0, "_array_set_item", 0
db 0x5a, 0x81, 0, 0, "_array_append", 0
db 0x5f, 0x81, 0, 0, "_get_obj_var", 0
db 0x64, 0x81, 0, 0, "_set_obj_var", 0
db 0x69, 0x81, 0, 0, "print", 0
db 0x6e, 0x81, 0, 0, "puts", 0
db 0x73, 0x81, 0, 0, "exit_process", 0
