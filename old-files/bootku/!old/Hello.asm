
org 100h
jmp begin

hellomsg	db 'Hello world...',13,10
		db 'Contoh program .COM, dibuat menggunakan FASM (Flat Assembler).',13,10,13,10
		db 'Tekan sembarang untuk keluar...',13,10,13,10,0

include 'INCLUDE\SYSTEM.INC'
include 'INCLUDE\SCREEN.INC'
include 'INCLUDE\KEYBOARD.INC'

begin:
   ;call _cls
      getcursor
      call _forcelinefeed
   print hellomsg
   readkey
   mov ax, 5048h
   cmp dx, ax
   jz _exittoKOS
_exittoDOS:
   int 20h

_exittoKOS:
   retf