
org 100h
jmp begin

runmode 	dw 0
appinfo 	db 'KEYBOARD ASCII',13,10,13,10
		db 'Program dibuat menggunakan FASM, oleh:',13,10
		db '   Nama: HERMAN SUMANTRI',13,10
		db '   NIM : 9852130011',13,10,13,10
		db 'Setiap ada tombol yang ditekan, kode heksa tombol akan ditampilkan di layar.',13,10
		db 'Tekan <Esc> untuk keluar program!',13,10,13,10,0
keystring	db 'Kode ASCII: ',0

INCLUDE 'INCLUDE\LOADALL.INC'

begin:
   mov [runmode], dx
   getcursor
   call _forcelinefeed
   ;call _cls
   print appinfo
rdkeyrepeat:
   readkey
   print keystring
_extkeyread:
   whex wordstrvalue, ax
   print wordstrvalue
   call _forcelinefeed
   cmp al, 27
   jnz rdkeyrepeat
quit:
   mov ax, 5048H
   cmp [runmode], ax
   jz ToKOS
ToDOS:
   int 20h
ToKOS:
   retf

_dummyarea:

