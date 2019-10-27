

org 100h
jmp begin

;FLOPPY FORMAT
;Ofs Length  Field                      Sample Value
;00  word    jmp command                    EB3C
;02  byte    nop command                      90
;03 08 bytes system version             MSWIN4.1
;0B  word    bytes/sector                   0200
;0D  byte    sectors/cluster                  01
;0E  word    reserved sectors               0001
;10  byte    number of FATs                   02
;11  word    max. root entries              00E0
;13  word    small total sectors            0B40
;15  byte    media descriptor byte            F0
;16  word    sectors/FAT                    0009
;18  word    sectors/track                  0012
;1A  word    disk heads                     0002
;1C  word    hidden sectors                 0000
;1E  word    reserved                       0000

;Following fields start from DOS 4+
;20  dword   huge total sectors         00000B40    ;if offset 13 contain zero
;24  byte    physical drive number            00
;25  byte    reserved                         00
;26  byte    signature byte                   29
;27  dword   volume serial number       350518E3
;2B 11 bytes volume label                BOOT95B
;36 08 bytes file system                 FAT12
;3E          boot code

;Alternative fields:
;  19 24 Sectors per FAT       000004FF
;  1D 28 Extended flags            0000
;  21 2C Root cluster number   00000002
;  25 30 FSI Sector Number         0001
;  38 43 Volume Serial Number  39280A08
;  3C 47 Volume Label (11 bytes)NO NAME
;  Observed:
;     52 File System (8 bytes)    FAT32

runmode 	dw 0
msgdrive	db '-- Current Drive Number  : ',0
msgsysver	db '03 System Version        : ',0
msgbps		db '0B Bytes per sector      : ',0
msgspc		db '0D Sectors per cluster   : ',0
msgrsvdscts	db '0E Reserved sectors      : ',0
msgfats 	db '10 Number of FATs        : ',0
msgmaxrootents	db '11 Max. Root Entries     : ',0
msgsmlsectors	db '13 Small Total Sectors   : ',0
msgmediadscrpt	db '15 Media Descriptor Byte : ',0
msgsctsperfat	db '16 Sectors per FAT       : ',0
msgsctspertrk	db '18 Sectors per Track     : ',0
msgdiskheads	db '1A Disk Heads            : ',0
msghdnsectors	db '1C Hidden Sectors        : ',0
msgrsvdfield1	db '1E Reserved Field        : ',0
msghugesectors	db '20 Huge Total Sectors    : ',0
msgdrvnumber	db '24 Physical Drive Number : ',0
msgrsvdfield2	db '25 Reserved Field        : ',0
msgsignature	db '26 Signature byte        : ',0
msgvolsn	db '27 Volume Serial Number  : ',0
msgvollbl	db '2B Volume Label          : ',0
msgfilesystem	db '36 File System           : ',0
msgerror	db 'Error.',13,10,0

include 'INCLUDE\LOADALL.INC'

_rdbootsector:
   ;CH=track, DH=head, DL=drive, CL=sector
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push bx
   mov cx, 2
_rdbootloop:
   push cx
   mov bx, [bp+6]	;readbuffer
   mov ax, [bp+4]
   mov dl, al		 ;drive
   mov ch, 0		 ;cylinder/track
   mov cl, 1		 ;absolute sector
   mov dh, al		 ;head
   test al, al
   jz _rddiskbootrec
   mov dh, 1		 ;hd head
_rddiskbootrec:
   mov ax, 0201h	 ;AL=sectors
   int 13h
   pop cx
   jnc _rdbootsuccess
   call _resetdisk
   loop _rdbootloop
_rdbootsuccess:
   pop bx
   pop dx
   pop cx
   pop ax
   pop bp
   ret 4

macro readbootsector sectorbuffer, drive
  {push sectorbuffer
   push drive
   call _rdbootsector}

_printbsi:
   push ax
   lodsb
   hex bytestrvalue, ax
   print bytestrvalue
   call _forcelinefeed
   pop ax
   ret

_printwsi:
   push ax
   lodsw
   whex wordstrvalue, ax
   print wordstrvalue
   call _forcelinefeed
   pop ax
   ret

macro printbsi {call _printbsi}
macro printwsi {call _printwsi}


begin:
   mov [runmode], dx
   push dx
   call _cls
   pop dx
      ;cmp dx, 5048h
   ;mov ax, 3830h
      ;jnz _getdiskinfo

   mov si, 82h
   ltrim si, _edtbuffer, cx
   mov ah, [si+0]
   mov al, [si+1]
_getdiskinfo:
   mov dx, ax
   bval

   readbootsector _bootsector, ax
   getdiskstatus
   jnc _bootsectorread
   print msgerror
   jmp quit

_bootsectorread:
   mov si, _bootsector
   cld

   print msgdrive
   xchg dh, dl
   putchar dx
   xchg dh, dl
   putchar dx
   call _forcelinefeed

   ;08 bytes at 03
   add si, 3
   mov al, 0
   print msgsysver
   mov ah, [si+8]
   mov [si+8], al
   print si
   call _forcelinefeed
   mov [si+8], ah
   add si, 8

   ;word at 0B
   print msgbps
   printwsi

   ;byte at 0D
   print msgspc
   printbsi

   ;word at 0E
   print msgrsvdscts
   printwsi

   ;byte at 10
   print msgfats
   printbsi

   ;word at 11
   print msgmaxrootents
   printwsi

   ;word at 13
   print msgsmlsectors
   printwsi

   ;byte at 15
   print msgmediadscrpt
   printbsi

   ;word at 16  (dword at 24)
   mov bx, [si]
   print msgsctsperfat
   test bx, bx
   jz _altsctperfat
   printwsi
   jmp _getsctpertrk
_altsctperfat:
   push si
   add si, 14
   lodsw
   mov dx, ax
   lodsw
   whex wordstrvalue, ax
   print wordstrvalue
   whex wordstrvalue, dx
   print wordstrvalue
   putchar '+'
   call _forcelinefeed
   pop si
   add si, 2

_getsctpertrk:
   ;word at 18
   print msgsctspertrk
   printwsi

   ;word at 1A
   print msgdiskheads
   printwsi

   ;word at 1C
   print msghdnsectors
   printwsi

   ;word at 1E
   print msgrsvdfield1
   printwsi

   ;dword at 20
   print msghugesectors
   lodsw
   mov dx, ax
   lodsw
   whex wordstrvalue, ax
   print wordstrvalue
   whex wordstrvalue, dx
   print wordstrvalue
   call _forcelinefeed

   ;byte at 24
   print msgdrvnumber
   printbsi

   ;byte at 25
   print msgrsvdfield2
   printbsi

   ;byte at 26
   print msgsignature
   printbsi

   ;dword at 27 (dword at 43)
   print msgvolsn
   test bx, bx
   jz _altvolsn
   lodsw
   mov dx, ax
   lodsw
   whex wordstrvalue, ax
   print wordstrvalue
   whex wordstrvalue, dx
   print wordstrvalue
   call _forcelinefeed
   jmp _getvollbl
_altvolsn:
   push si
   add si, 1Ch
   lodsw
   mov dx, ax
   lodsw
   whex wordstrvalue, ax
   print wordstrvalue
   whex wordstrvalue, dx
   print wordstrvalue
   putchar '+'
   call _forcelinefeed
   pop si
   add si, 4

_getvollbl:
   ;11 bytes at 2B (11 bytes at 47)
   print msgvollbl
   test bx, bx
   jnz _getvolumelabel
   add si, 1Ch
_getvolumelabel:
   mov al, 0
   mov ah, [si+11]
   mov [si+11], al
   print si
   call _forcelinefeed
   mov [si+11], ah
   add si, 11

   ;08 bytes at 36 (08 bytes at 52)
   print msgfilesystem
   mov al, 0
   mov ah, [si+8]
   mov [si+8], al
   print si
   mov [si+8], ah
   add si, 8
   call _forcelinefeed
   call _forcelinefeed

quit:
   mov ax, 5048h
   cmp [runmode], ax
   jnz _exittodos
   retf
_exittodos:
   int 20h


_edtbuffer	rb 20h
_bootsector	rb 201h

_diskbuffer	rb 1
_fatbuffer	rb 1
_tmprdbuffer	rb 1

_dummyarea: