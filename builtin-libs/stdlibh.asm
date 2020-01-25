dw code

dw 8

dw int_add, 9
  db "[int_add]"
dw int_subtract, 14
  db "[int_subtract]"
dw int_multiply, 14
  db "[int_multiply]"
dw int_divide, 12
  db "[int_divide]"
dw int_add, 9
  db "[int_and]"
dw int_or, 8
  db "[int_or]"
dw get_obj_var, 13
  db "[get_obj_var]"
dw set_obj_var, 13
  db "[set_obj_var]"

code:
include 'stdlib.asm'
