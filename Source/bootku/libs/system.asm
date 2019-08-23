hpKeyEsc	equ 0011Bh
hpKeyEtr	equ 01C0Dh
hpKeySp 	equ 03920h
hpKeyUp 	equ 048E0h
hpKeyDn 	equ 050E0h
hpKeyLt 	equ 04BE0h
hpKeyRt 	equ 04DE0h
hpKeyHm 	equ 047E0h
hpKeyEd 	equ 04FE0h
hpKeyBs 	equ 00E08h
hpKeyTb 	equ 00F09h

FNDBYPASS	equ 10h
FNDNOTFOUND	equ 20h
FNDFOUND	equ 11h

ATTRNORMAL	equ 00
ATTRRDONLY	equ 01
ATTRHIDDEN	equ 02
ATTRSYSTEM	equ 04
ATTRVOLLBL	equ 08
ATTRWINFILE	equ 0Fh
ATTRFOLDER	equ 10h
ATTRARCHIVE	equ 20h


struc filebufferheader
{
  .name 	rb 8
  .ext		rb 3
  .attr 	db ?
  .res		rb 10
  .time 	dw ?
  .date 	dw ?
  .clst 	dw ?
  .size 	dw ?
  .szhi 	dw ?
  .used 	db ?
  .buffer	dw ?
  .clusternbr	dw ?
  .crtcluster	dw ?
  .nxtcluster	dw ?
  .rdcapacity	dw ?
  .rdoffset	dw ?
  .seek 	dw ?
  .eof		db ?
  .unused	rb 2
}


_dftscrclr	equ 7
_execsegment	equ 2000h
_execoffset	equ 0100h

_mainfatbuffer	dw 0		;400h bytes
_dskrdbuffer	dw 0		;801h bytes
_dskwrbuffer	dw 0		;801h bytes
_mainsctbuffer	dw 0		;201h bytes
_sysfiletable	filebufferheader

_crtcluster	dw 0
_crtschatr	dw 0
_crtschofs	dw 0		;current search offset
_crtschstt	db 0
_crtfatsct	dw 0
_crtdirsct	dw 0		;Sector of current directory
_crtentry	db 0		;Current entry in current sector

_cursorpos	dw 0
_screenptr	dw 0

_syssegment	dw 0		;Return segment of app. loaded
_sysoffset	dw 0		;Return offset of app. loaded

_freeheap	dw 0
_heapsize	dw 0
_runmode	dw 0
_nullvar	dw 0

wordstrvalue	db 0,0
bytestrvalue	db 0,0,0

_sysfilename	rb 13
_syscmdbuffer	rb 20h
_sysedtbuffer	rb 20h

maxmemhandles	equ 20h
freememhandle	dw 0
memalloctable	dw 0


