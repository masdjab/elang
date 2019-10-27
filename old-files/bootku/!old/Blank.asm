org 100h
jmp begin

include 'INCLUDE\LOADALL.INC'



begin:
  call _sysinit

  int 20h


_dummyarea: