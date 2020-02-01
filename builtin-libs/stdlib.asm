dw code

dw 15

dw mem_block_init, 14
  db "mem_block_init"
dw mem_alloc, 9
  db "mem_alloc"
dw mem_dealloc, 11
  db "mem_dealloc"
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
dw _get_obj_var, 12
  db "_get_obj_var"
dw _set_obj_var, 12
  db "_set_obj_var"
dw _puts, 4
  db "puts"
dw _getch, 5
  db "getch"

code:
include 'stdproc.asm'
