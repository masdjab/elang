
org 100h
jmp begin
runmode 	dw 0
OSStart 	db 'PROGRAM SISTEM OPERASI ',13,10,13,10,0
;==================================================================
crtby		db 'dibuat oleh:',13,10,0
usernm		db '   Nama: HERMAN SUMANTRI',13,10
userid		db '   NIM : 9852130011',13,10,13,10

		;   123456789012345
		;   HERMAN SUMANTRI
ecnm		db 'USERNAME       ',0
nmsz		equ 15
		;   985213011
ecid		db 'USERID   ',0
idsz		equ 9
;==================================================================
OSInfo		db 'Sistem operasi ini dapat menampilkan isi file teks ke layar',13,10
		db 'dan menjalankan program .COM atau .EXE',13,10,13,10
		db '+ Ketikkan DIR untuk melihat file di disket',13,10
		db '+ Ketikkan CLS untuk menghapus layar',13,10
		db '+ Ketikkan nama file teks untuk melihat isinya',13,10
		db '+ Ketikkan nama file .COM atau .EXE untuk dijalankan',13,10,0
OSHelp		db 'Ketikkan perintah atau nama file .TXT, .EXE atau .COM.',13,10
exithlp 	db 'Ketik "EXIT" untuk keluar.',13,10,13,10,0
cmdprompt	db 'A:> ',0
msgend		db 'Sesi selesai. Matikan CPU!',13,10,0
listinfo	db 'File di drive A:',13,10,0
badcmd		db 'Perintah atau nama file tidak valid.',13,10,0
notexecutable	db ' bukan file teks atau file executable.',13,10,13,10,0
simulate	db 'Eksekusi program mode DOS atau Windows.',13,10,13,10,0
nofilemsg	db 'Tidak ada file di drive A:.',13,10,0
diskerrmsg	db 'Error pada saat membaca disket. Error #',0
wordstrvalue	rb 2
bytestrvalue	rb 3
filetext	db ' file.',13,10,13,10,0
spaces		db '   ',0
cmdexit 	db 'EXIT',0
cmdlist 	db 'DIR',0
cmdcls		db 'CLS',0
cmdhlp		db 'HELP',0
cmdqst		db '?',0
txtext		db '.TXT'
exeext		db '.EXE'
comext		db '.COM'
dbldot		db ':',0
spcchr		db ' ',0
txtlength	dw 0
cmdlength	dw 0
prmlength	dw 0
filename	rb 13

include 'INCLUDE\LOADALL.INC'

_setrestorepoint:		;Catat lokasi CS:IP sekarang
   push bp			;agar dapat kembali ke prompt
   mov bp, sp			;setelah mengeksekusi program
   mov [_syssegment], cs	;.EXE atau .COM
   mov ax, [bp+02]
   mov [_sysoffset], ax
   pop bp
   ret

begin:
   mov ax, cs			;Set semua register segmen,
   mov ds, ax			;samakan dengan register CS
   mov ss, ax
   mov sp, 0FFFEh
   mov [runmode], dx
   call _cls
   push es
   push ds
   getcursor
   print OSStart		;Tampilkan logo Sistem Operasi
;==================================================================
      print crtby
      mov al, 0
      mov di, edtbuffer
      stringcopy usernm, di, 9
      add di, 9
      decrypt ecnm, di, nmsz
      add di, nmsz
      mov [di], al
      print edtbuffer
      call _forcelinefeed
	 mov di, edtbuffer
	 stringcopy userid, di, 9
	 add di, 9
	 decrypt ecid, di, idsz
	 add di, idsz
	 mov [di], al
	 print edtbuffer
	 call _forcelinefeed
      call _forcelinefeed
;==================================================================
   print OSInfo
   print exithlp
   call _setrestorepoint
   pop ds			;Ambil kembali nilai DS dan ES
   pop es			;setelah mengeksekusi program
   getcursor
   call _forcelinefeed

CMDREADY:
   print cmdprompt		;Tampilkan command prompt
   input cmdbuffer		;dan baca perintah dari user
   call _forcelinefeed
   ltrim cmdbuffer, cmdbuffer, cx
   mov [txtlength], cx
   push cx
   mov ax, cx
   getwordsize cmdbuffer
   mov [cmdlength], cx
   sub ax, cx
   mov [prmlength], ax
   test cx, cx
   pop cx
   jnz _evalusrtext
_emptycommand:
   call _forcelinefeed		;Kembali ke prompt jika teks
   jmp CMDREADY 		;perintahnya string kosong
_evalusrtext:
   ucase cmdbuffer, edtbuffer, cx
   mov si, edtbuffer
   add si, cx
   mov al, 0
   mov [si], al
   cmpwdstring edtbuffer, cmdexit
   jz exit

CMDDIR:
   cmpwdstring edtbuffer, cmdlist
   jnz _CLEARSCREEN
   print listinfo
   resetsearch
   xor cx, cx
_dirschnextfile:
   findfile filename
   jnz _endofdir
   jc _dirschnextfile
   mov si, [_crtschofs]
   test byte [si+0Bh], 10h
   pushf
   mov al, 0
   mov [si+11], al
   print spaces
   popf
   jz _notdiropen
   putchar '\'
_notdiropen:
   print si
   inc cx
   call _forcelinefeed
   jmp _dirschnextfile
_endofdir:
   test cx, cx
   jz _nomorefilefound
   whex wordstrvalue, cx
   print wordstrvalue
   print filetext
   jmp CMDREADY
_nomorefilefound:
   print nofilemsg
   call _forcelinefeed
   jmp CMDREADY

_CLEARSCREEN:
   cmpwdstring edtbuffer, cmdcls
   jnz _HELP
   call _cls
   jmp CMDREADY

_HELP:
   cmpwdstring edtbuffer, cmdhlp
   jz _showhelp
   cmpwdstring edtbuffer, cmdqst
   jz _showhelp

_EXECUTEFILE:
   resetsearch
_schexefile:
   findfile filename
   jnz _INVALIDCMD
   jc _schexefile
   mov si, edtbuffer
   mov di, filename
   cmpwdstring si, di
   jnz _schexefile
   getwordsize si
   add si, cx
   add di, cx
   mov al, '.'
   cmp [si], al
   jnz _crtfilematch
   mov dx, si
   inc dx
   getwordsize dx
   add dx, cx
   inc cx
   cmpstring si, di, cx
   jnz _schexefile
_crtfilematch:
   cmpstring di, txtext, 3
   jz _TXTHANDLE
   cmpstring di, comext, 3
   jz _EXEHANDLE
   cmpstring di, exeext, 3
   jz _EXEHANDLE
   print filename
   print notexecutable
   jmp CMDREADY

_TXTHANDLE:
   mov si, [_crtschofs]
   loadfile si, es, _tmprdbuffer
   mov si, _tmprdbuffer
   add si, cx
   mov al, 0
   mov [si], al
   print _tmprdbuffer
   call _forcelinefeed
   call _forcelinefeed
   jmp CMDREADY

_EXEHANDLE:
   mov ax, 5048H
   cmp [runmode], ax
   mov ax, _execsegment
   jz _execready
_runDOS:
   print simulate
   mov ax, es
   add ax, 400h
_execready:
   push es
   push ds
   mov si, [_crtschofs]
   loadfile si, ax, _execoffset
   push [_syssegment]
   push [_sysoffset]
   mov si, cmdbuffer
   mov dx, [cmdlength]
   add si, dx
   mov cx, [prmlength]
   ltrim si, si, cx
   mov es, ax
   push ax
   stringcopy si, 0, cx
   add si, cx
   mov al, 0
   mov [si], al
   pop ax
   mov ds, ax
   push es
   push _execoffset
   mov dx, 5048H
   retf

_INVALIDCMD:
   print badcmd
_showhelp:
   print OSHelp
   jmp CMDREADY

exit:
   mov ax, 5048h
   cmp [runmode], ax
   jz exitboot
   int 20h
exitboot:
   print msgend
   hlt


;SYSTEM BUFFER:
_diskbuffer	rb 201h
_fatbuffer	rb 201h
_tmprdbuffer	rb 801h
_syssegment	dw 0		;Return segment of app. loaded
_sysoffset	dw 0		;Return offset of app. loaded

;ADDITIONAL BUFFER:
cmdbuffer	rb 100h
edtbuffer	rb 100h

;command parameter

