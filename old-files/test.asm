org 0100h
jmp main
puts:
  ret
  
main:
  call puts
  int 20h
