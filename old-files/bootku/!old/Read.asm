

org 100h
jmp begin
struc filebufferheader
{
  .name 	rb 8		;0112
  .ext		rb 3
  .attr 	db ?
  .res		rb 10
  .time 	dw ?
  .date 	dw ?
  .clst 	dw ?		;012D
  .size 	dw ?
  .szhi 	dw ?
  .used 	db ?
  .memhandle	dw ?
  .buffer	dw ?
  .clusternbr	dw ?
  .crtcluster	dw ?
  .nxtcluster	dw ?
  .rdcapacity	dw ?
  .rdoffset	dw ?
  .seek 	dw ?
  .eof		db ?
  .unused	rb 16
}

;filename                db 'SECTOR  TXT',0,0
filename		db 'LINES   TXT',0,0
;===============================================
fhthandle	dw 0
fhtable 	filebufferheader
frdhandle	dw 0
;===============================================
txtnotfound	db 'File not found!',13,10,0

include 'INCLUDE\LOADALL.INC'


initfhtable:
   push ax
   memalloc 40h, fhthandle
   mov ax, [_freeheap]
   memalloc 200h, fhtable.memhandle
   mov word [fhtable.buffer], ax
   pop ax
   ret


begin:
   call _sysinit
   call initfhtable
   fileopen filename, frdhandle
   jc _filenotfound
   ;fileread frdhandle, tmpbuffer, 40h
   ;print tmpbuffer
   ;   fileseek 1, 40h
   ;   fileread frdhandle, tmpbuffer, 40h
   ;   print tmpbuffer
   mov cx, 4
   fileread frdhandle, tmpbuffer, 40h


   fileclose frdhandle
   jmp exit

_filenotfound:
   print txtnotfound
   forcelinefeed
exit:
   int 20h


tmpbuffer	rb 41h

_dummyarea:

