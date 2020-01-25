dw code

dw 10

dw _int_add, 9
  db "_int_add"
dw _int_subtract, 14
  db "_int_subtract"
dw _int_multiply, 14
  db "_int_multiply"
dw _int_divide, 12
  db "_int_divide"
dw _int_add, 9
  db "_int_and"
dw _int_or, 8
  db "int_or"
dw _get_obj_var, 13
  db "_get_obj_var"
dw _set_obj_var, 13
  db "_set_obj_var"
dw _puts, 4
  db "puts"
dw _getch, 5
  db "getch"

code:
include 'stdproc.asm'
