dw code

dw 37

dw mem_block_init, 14
  db "mem_block_init"
dw mem_alloc, 9
  db "mem_alloc"
dw mem_dealloc, 11
  db "mem_dealloc"
dw mem_get_data_offset, 19
  db "mem_get_data_offset"
dw alloc_object, 12
  db "alloc_object"
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
dw load_str, 8
  db "load_str"
dw str_length, 10
  db "str_length"
dw str_lcase, 9
  db "str_lcase"
dw str_ucase, 9
  db "str_ucase"
dw str_concat, 10
  db "str_concat"
dw str_append, 10
  db "str_append"
dw str_substr, 10
  db "str_substr"
dw _print, 5
  db "print"
dw _puts, 4
  db "puts"
dw _getch, 5
  db "getch"

code:
include 'stdproc.asm'
