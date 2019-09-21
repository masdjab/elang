

org 100h
jmp begin

include 'INCLUDE\LOADALL.INC'

msgprm		db 'Command parameter: ',0
msglen		db 'Parameter length : ',0
msgdos		db 'Cannot run under DOS or Windows!',13,10,0


begin:
   call _sysinit
   mov ax, 5048h
   cmp dx, ax
   jnz _exittodos

   call _cls
   print msgprm
   print 82h
   forcelinefeed
   print msglen
   whex wordstrvalue, cx
   print wordstrvalue
   forcelinefeed
   retf

_exittodos:
   print msgdos
   forcelinefeed
   int 20h


_dummyarea: