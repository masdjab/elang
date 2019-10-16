

org 100h
jmp begin

runmode 	dw 0
formattin	db 'Formatting floppy disk...',0
formatted	db 'Floppy disk formatted.',13,10,0

include 'INCLUDE\LOADALL.INC'

localdelay:
   push cx
   xor cx, cx
locdlyloophere:
   loop locdlyloophere
   pop cx
   ret

begin:
   mov [runmode], dx
   getcursor
   test byte [_cursorpos], 15
   jz _linefed
   forcelinefeed

_linefed:
   mov ax, cs
   print formattin
   call localdelay
   strfill _fatcontent, 200h, 0

   mov cx, 07
   mov ax, 03
   mov dx, 12
   mov bx, 13h
   mov si, 1Ah
   ;call _resetdisk
_writeblanksector:
   pusha
   writesector _fatcontent, 0, ax, 1
   writesector _fatcontent, 0, dx, 1
   writesector _fatcontent, 0, bx, 1
   writesector _fatcontent, 0, si, 1
   popa
   inc ax
   inc dx
   inc bx
   inc si
   loop _writeblanksector

   writesector _fatcontent, 0, 02, 1
   writesector _fatcontent, 0, 11, 1
   mov di, _fatcontent
   mov ax, 0FFF0h
   stosw
   mov [di], ah
   writesector _fatcontent, 0, 01, 1
   writesector _fatcontent, 0, 10, 1

   forcelinefeed
   print formatted
   mov ax, 5048h
   cmp [runmode], ax
   jnz _exittodos
   retf
_exittodos:
   int 20h



_fatcontent	rb 200h
_diskbuffer	rb 1
_fatbuffer	rb 1
filename	db 0

