
org 100h
jmp begin

runmode 	dw 0
prmlength	dw 0
txtnotfound	db ' tidak ditemukan.',13,10,0
txtnotspcfd	db 'Nama file tidak disebutkan.',13,10
		db 'Ketik: TAMPIL[.COM] NAMAFILE[.TXT]',13,10,0
txtnotvalid	db 'Nama file tidak valid.',13,10,0
endofsearch	db 'Selesai mencari file.',13,10,0
contentof	db 'Isi dari file '
filename	rb 13

include 'INCLUDE\LOADALL.INC'

begin:
   mov [runmode], dx
   initialize
   getcursor
_linefed:
   test cx, cx
   jz _noprmentered
   mov si, 0
   mov di, _edtbuffer
   ltrim si, si, cx
   push si
   add si, cx
   mov al, 0
   mov [si], al
   pop si
   getwordsize si
   test cx, cx
   jnz _prmfound
_noprmentered:
   print txtnotspcfd
   jmp _exittxtviewer
_prmfound:
   cmp cx, 9
   jnc _invalidtxt
_shorttxtfilename:
   mov di, _edtbuffer
   ucase si, di, 12
   mov ax, 2E00h
   mov [di+12], al
   getwordsize di
   mov [prmlength], cx
   add di, cx
   cmp [di], ah
   jnz _txtfilenameok
   inc di
   inc word [prmlength]
   getwordsize di
   cmp cx, 4
   jnc _invalidtxt
   add [prmlength], cx
   add di, cx
_txtfilenameok:
   mov [di], al

   resetsearch
_schtxtfile:
   findfile filename
   jnz _txtfilenotfound
   jc _schtxtfile
   cmpstring filename, _edtbuffer, [prmlength]
   jnz _schtxtfile
   cmpwdstring filename, _edtbuffer
   jnz _schtxtfile
   print contentof
   call _forcelinefeed
   call _forcelinefeed
   mov ax, es
   mov si, [_crtschofs]
   loadfile si, ax, _textbuffer
   mov si, _textbuffer
   mov al, 0
   add si, cx
   mov [si], al
   print _textbuffer
   call _forcelinefeed
   jmp _exittxtviewer
_txtfilenotfound:
   print _edtbuffer
   print txtnotfound
   jmp _exittxtviewer
_invalidtxt:
   print txtnotvalid
_exittxtviewer:
   mov ax, 5048h
   cmp [runmode], ax
   jnz _exittodos
   retf
_exittodos:
   int 20h


_edtbuffer	rb 10h
_diskbuffer	rb 201h
_fatbuffer	rb 201h
_textbuffer	rb 400h

wordstrvalue	db 0, 0
bytestrvalue	db 0, 0, 0

