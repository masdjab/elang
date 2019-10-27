

org 0
jmp starthere

;Data parameter disket
diskdata	db 90h
		db 'MR/C 1.0'
bytespersector	dw 200h
sctspercluster	db 01
reservedscts	dw 0001
numberoffats	db 02
maxentries	dw 00E0h
tinysectors	dw 0B40h
mediadescriptor db 0F0h
sectorsperfat	dw 0009
sectorspertrk	dw 0012h
diskheads	dw 0002
hdnsectors	dw 0000
reserved01	dw 0000
hugesectors	dd 00000B40h
drivenumber	db 00
reserved02	db 00
signaturebyte	db 29h
volserialnbr	db 05,20h,04,28h
vollabel	db 'MYBOOTDISK '
filesystem	db 'FAT 12  '

starthere:
   push cs
   pop ss		;samakan SS dengan CS
   mov sp, 7C00h	;set stack pointer = 7C00H
   mov ax, 7C0h 	;set DS dan ES  = 07C0H
   mov ds, ax
   mov es, ax
   jmp begin

_getbioscursor: 			;Rutin untuk memperoleh kursor BIOS
   push ax
   push bx
   xor bh, bh
   mov ah, 3
   int 10h
   xor dl, dl
   mov [_rowcolumn], dx 		;Simpan data baris dan kolom
   pop bx
   pop ax
   ret

_feednewline:				;Rutin ganti baris
   inc byte [_rowcolumn + 01]
_setcursorhome:
   mov byte [_rowcolumn], 0
_setcursorpos:
   cmp byte [_rowcolumn + 01], 25
   jc _setscreenptr
_scrolllineup:
   mov ax, 0601h
   mov cx, 0
   mov dx, 1950h
   mov bh, 7
   int 10h
   mov byte [_rowcolumn + 01], 24
_setscreenptr:
   mov dx, [_rowcolumn]
   push dx
   xor ah, ah
   mov al, 80
   mul dh
   add al, dl
   jnc _refinescrptr
   inc ah
_refinescrptr:
   mov di, 02
   mul di
   mov di, ax
   pop dx
_cursorrefresh:
   xor bh, bh
   mov ch, 6
   mov cl, 7
   mov ah, 2
   int 10h
   ret

_BIOSPrint:				;Cetak string ke layar
   push bp
   mov bp, sp
   push ax
   push cx
   push es
   push si
   call _setscreenptr
   xor cx, cx
   mov ax, 0B800h
   mov es, ax
   mov si, [bp+04]
   cld
_BPRepeat:
   lodsb
   test al, 0FFH
   jz _BPExit
   cmp al, 13
   jnz _testformovehome
   call _feednewline
   jmp _BPRepeat
_testformovehome:
   cmp al, 10
   jnz _printablechars
   call _setcursorhome
   jmp _BPRepeat
_printablechars:
   inc byte [_rowcolumn]
   mov ah, 7
   stosw
   jmp _BPRepeat
_BPExit:
   call _setcursorpos
   pop si
   pop es
   pop cx
   pop ax
   pop bp
   ret 2

macro BIOSPrint stroffset
  {push stroffset
   call _BIOSPrint}

_rstdisk:		;Reset floppy disk
   push ax
   push cx
   push dx
   mov cx, 7
_rstdiskretry:
   xor ah, ah
   mov dl, 0		;drive number (0=drive A:)
   int 13h
   jnc _rstdiskok
   loop _rstdiskretry
_rstdiskok:
   pop dx
   pop cx
   pop ax
   ret			;Carry=1 if error

_settrhdsct:
   push ax		;Konversi sektor logikal
   push bx		;ke No. Track, Head dan Sector Absolut
   push dx
   mov bx, 24h
   div bl
   mov ch, al
   mov bx, 12h
   xchg ah, al
   xor ah, ah
   div bl
   pop dx
   mov dh, al
   mov cl, ah
   inc cl
   pop bx
   pop ax
   ret

_readlogical:		;Baca sektor logikal
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push bx
   mov bx, [bp+10]	;buffer
   mov ax, [bp+08]
   mov dl, al		;drive
   mov ax, [bp+06]	;absolute sector
   mov cx, [bp+4]	;sectors
_rdnxtlgcsct:
   push cx
   push ax
   call _settrhdsct
   mov ax, 0201h	;read 01 sector, use service 02
   int 13h
   jnc _rdcrtsctcok
   call _rstdisk
_rdcrtsctcok:
   pop ax
   pop cx
   inc ax
   add bx, 200h
   loop _rdnxtlgcsct
   pop bx
   pop dx
   pop cx
   pop ax
   pop bp
   ret 8

macro readlogical buffer, drive, sector, sectors
  {push buffer
   push drive
   push sector
   push sectors
   call _readlogical}


begin:
   call _getbioscursor		;Dapatkan baris kolom layar sekarang
   BIOSPrint logo		;Tampilkan logo
   mov ax, 1000h
   mov es, ax
   mov si, 100h
   readlogical si, 0, 13h, 1
   mov ax, [si+1Ch]
   mov bx, 200h
   xor dx, dx
   div bx
   inc ax
   mov cx, ax
   mov ax, 21h
_readnextsector:
   readlogical si, 0, ax, 1
   add si, bx
   inc ax
   loop _readnextsector
   mov ax, 100h
   mov dx, 5048H
   push es			;Lompat ke sistem operasi
   push ax			;yang diload dari disket
   retf 			;di alamat 1000:0100h

_rowcolumn	dw 0
_screenofs	dw 0
logo		db "Starting Kecrut's Boot Loader...",13,10,0
scrlinefeed	db 13,10,0


