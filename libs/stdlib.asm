dw code

dw 42

dw _mem_block_init, 15
  db "_mem_block_init"
dw _mem_alloc, 10
  db "_mem_alloc"
dw _mem_dealloc, 12
  db "_mem_dealloc"
dw _mem_get_data_offset, 20
  db "_mem_get_data_offset"
dw _alloc_object, 13
  db "_alloc_object"
dw _is_object, 10
  db "_is_object"
dw _increment_object_ref, 21
  db "_increment_object_ref"
dw _decrement_object_ref, 21
  db "_decrement_object_ref"
dw _unassign_object, 16
  db "_unassign_object"
dw _collect_garbage, 16
  db "_collect_garbage"
dw _cbw, 4
  db "_cbw"
dw _cwb, 4
  db "_cwb"
dw _get_byte_at, 12
  db "_get_byte_at"
dw _set_byte_at, 12
  db "_set_byte_at"
dw _get_word_at, 12
  db "_get_word_at"
dw _set_word_at, 12
  db "_set_word_at"
dw _int_pack, 9
  db "_int_pack"
dw _int_unpack, 11
  db "_int_unpack"
dw _int_add, 8
  db "_int_add"
dw _int_subtract, 13
  db "_int_subtract"
dw _int_multiply, 13
  db "_int_multiply"
dw _int_divide, 11
  db "_int_divide"
dw _int_add, 8
  db "_int_and"
dw _int_or, 7
  db "_int_or"
dw _int_to_h8, 10
  db "_int_to_h8"
dw _int_to_h16, 11
  db "_int_to_h16"
dw _int_to_s, 9
  db "_int_to_s"
dw _is_equal, 9
  db "_is_equal"
dw _is_not_equal, 13
  db "_is_not_equal"
dw _is_true, 8
  db "_is_true"
dw _get_obj_var, 12
  db "_get_obj_var"
dw _set_obj_var, 12
  db "_set_obj_var"
dw _load_str, 9
  db "_load_str"
dw _str_length, 11
  db "_str_length"
dw _str_lcase, 10
  db "_str_lcase"
dw _str_ucase, 10
  db "_str_ucase"
dw _str_concat, 11
  db "_str_concat"
dw _str_append, 11
  db "_str_append"
dw _str_substr, 11
  db "_str_substr"
dw _print, 5
  db "print"
dw _puts, 4
  db "puts"
dw _getch, 5
  db "getch"

code:
include 'stdproc.asm'
