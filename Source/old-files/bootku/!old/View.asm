

org 100h
jmp begin

include 'INCLUDE\LOADALL.INC'
include 'INCLUDE\INTERFACE.INC'

msgloadingfile		db 'Loading file...',0
msgfilenotfound 	db 'File not found.',0
msgdskreaderror 	db 'Error reading diskette.',13,10,0
txtblank		rb  81
txtbytes		db ' bytes.',0
txtbfrsz		db 'Buffer size: ',0
txtendofbfr		db 'End of buffer!',0
filename		db 'NETWORK TXT',0
;filename                db 'LINES   TXT',0
;filename                db 'LINED   TXT',0
txtseek 		dw 0
viewoffset		dw 0			;relative to readbuffer
visiblechars		dw 0
rdbuffersize		dw 0
barcolour		dw 3Fh			;colour code for information bar
scrcolour		dw 15			;colour code for text view
fourspaces		db '    ',0
rdcapacity		dw 0			;capacity of read buffer in sector
fileopened		db 0			;0=not opened, 1=opened
lastlinesz		dw 0
rebufferflag		db 0


begin:
   call _sysinit
   clearscreen
   mov ax, dskrdbuffersize			;calculate capacity of
   and ax, 0FF00h				;read buffer in sectors
   mov [rdbuffersize], ax
   mov bx, 200h
   xor dx, dx
   div bx
   mov [rdcapacity], ax
_initializescreen:
   setcolour 0, 0, 80, [barcolour]		;create upper and lower
   setcolour 24, 0, 80, [barcolour]		;information bar
_setcursorpos:
   mov dx, 0100h				;set cursorpos at
   mov [_cursorpos], dx 			;row 01, coloumn 00;
   call _setscrptr				;set screen pointer;
   call _cursorrfsh				;then show cursor
   strfill txtblank, 80, ' '
   fileopen filename, _nullvar
   jc _filenotfound
   mov word [txtseek], 0
   puttext 24, 0, txtblank

loadtxtfile:
   test byte [fileopened], 0FFh
   mov ax, [rdcapacity] 			;number of sectors to read
   mov bx, [_dskrdbuffer]			;read buffer offset
   jz _loadclustersonce
_rebufferprev:
   mov si, [viewoffset]
   test si, si
   jnz _rebuffernext
   test [txtseek], 0FFFFh
   jz _rebuffernext
   mov ax, 200h
   mov cx, [rdbuffersize]
   sub cx, ax
   mov si, [_dskrdbuffer]
   add si, [rdbuffersize]
   dec si
   mov di, si
   sub si, ax
   std
   repnz
   movsb
   sub [txtseek], ax
   add [viewoffset], ax
   fileseek 1, [txtseek]
   mov bx, [_dskrdbuffer]
   mov ax, 1
   and word [lastlinesz], 7FFFh
   jmp _editrdnxtcluster
_rebuffernext:
   add si, [visiblechars]
   inc si
   cmp si, [rdbuffersize]
   ;jc _printtxtfileinfo
      jc _loadlastline
   chkeof
   ;jnz _printtxtfileinfo
      jnz _loadlastline
   mov ax, 200h
   mov cx, [rdbuffersize]
   sub cx, ax
   mov si, [_dskrdbuffer]
   mov di, si
   add si, ax
   push cx
   cld
   repnz
   movsb
   pop cx
   sub [viewoffset], ax
   add [txtseek], ax
   add cx, [txtseek]
   fileseek 1, cx
   mov bx, [_dskrdbuffer]
   add bx, [rdbuffersize]
   sub bx, 200h 		;rebuffer sector size
   mov ax, 1			;sectors to read
   or word [lastlinesz], 8000h
   jmp _editrdnxtcluster
_loadclustersonce:
   fileseek 1, 0
_editrdnxtcluster:
   puttext 24, 0, msgloadingfile
   mov cx, ax
_loadcrtcluster:
   fileread _nullvar, bx, 200h
   add bx, 200h
   loop _loadcrtcluster
_editclustersloaded:
   puttext 24, 0, txtblank
   mov ax, [rdbuffersize]
   mov cx, [_sysfiletable.size]
   sub cx, [txtseek]
   cmp cx, ax
   mov si, cx
   jc _trmstrbybfrsize
   mov si, ax
_trmstrbybfrsize:
   test byte [fileopened], 0FFh
   ;jnz _printcrtstatus
      jnz _loadlastline
   add si, [_dskrdbuffer]
   mov byte [si], 0
_editrepaintscreen:
   xor ax, ax
   mov si, [viewoffset]
   add si, [_dskrdbuffer]
   xor dx, dx
_editloadlines:
   inc ax
   puttext ax, 0, si
   add dx, cx
   add si, cx
   cmp word [si], 0A0Dh
   jnz _linefeedasked
   add si, 02
   add dx, 02
_linefeedasked:
   cmp dx, [_sysfiletable.size]
   jnc _saveloadedchars
   cmp ax, 23
   jc _editloadlines
_saveloadedchars:
   mov [visiblechars], dx
   locate 1, 0
   jmp _printtxtfileinfo

_loadlastline:
   ;test word [lastlinesz], 0FFFFh
   ;jz _lastlinecompleted
   ;test word [lastlinesz], 8000h
   ;jz _completetopline
   test byte [rebufferflag], 2
   jz _lastlinecompleted
   test byte [rebufferflag], 1
   jnz _completetopline
_completebtmline:
      mov si, [_dskrdbuffer]
      add si, [viewoffset]
      add si, [visiblechars]
      ;puttext 23, [lastlinesz], si
	 puttext 23, 0, si
      add cx, 2
      add [visiblechars], cx
      jmp _lastlinecompleted
_completetopline:

_lastlinecompleted:
   jmp _printcrtstatus

_printtxtfileinfo:
   puttext 0, 0, filename
   decstr _sysedtbuffer, [_sysfiletable.size]
   mov si, 13
   puttext 0, si, _sysedtbuffer
   add si, cx
   puttext 0, si, txtbytes
   puttext 0, 63, txtbfrsz
   whex wordstrvalue, [rdbuffersize]
   puttext 0, 76, wordstrvalue
   puttext 24, 0, txtblank
_printcrtstatus:
   whex wordstrvalue, [txtseek]
   puttext 0, 30, wordstrvalue
   whex wordstrvalue, [viewoffset]
   puttext 0, 36, wordstrvalue
   whex wordstrvalue, [visiblechars]
   puttext 0, 42, wordstrvalue
   mov si, [viewoffset]
   add si, [visiblechars]
   whex wordstrvalue, si
   puttext 24, 76, wordstrvalue
   mov byte [fileopened], 1

_editgetuserkey:
   readkey
      mov byte [rebufferflag], 0
      mov word [lastlinesz], 0
   puttext 24, 0, txtblank
_editusrkeyup:
   cmp ax, hpKeyUp
   jnz _editusrkeydn
   cursormove -1, 0
   jmp _evalcursorpos
_editusrkeydn:
   cmp ax, hpKeyDn
   jnz _editusrkeylt
   cursormove 1, 0
   jmp _evalcursorpos
_editusrkeylt:
   cmp ax, hpKeyLt
   jnz _editusrkeyrt
   cmp [_cursorpos], 0100h
   jz loadtxtfile
   cursormove 0, -1
   jmp _evalcursorpos
_editusrkeyrt:
   cmp ax, hpKeyRt
   jnz _editusrkeyhome
   cmp [_cursorpos], 174Fh
   jz loadtxtfile
   cursormove 0, 1
   jmp _evalcursorpos
_editusrkeyhome:
   cmp ax, hpKeyHm
   jnz _editusrkeyend
   mov dx, [_cursorpos]
   mov dl, 0
   mov [_cursorpos], dx
   jmp _evalcursorpos
_editusrkeyend:
   cmp ax, hpKeyEd
   jnz _editnotnavigatekey
   mov dx, [_cursorpos]
   mov dl, 79
   mov [_cursorpos], dx
   jmp _evalcursorpos
_editnotnavigatekey:
   cmp ax, hpKeyEsc
   jz exit
   cmp ax, hpKeyEtr
   jnz _editnotetrkey
   mov dx, [_cursorpos]
   xor dl, dl
   inc dh
   cmp dh, 24
   jc _editetrmoved
   mov dh, 24
_editetrmoved:
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
_editnotetrkey:
   cmp ax, hpKeyBs
   jnz _editprintablechar
   ;.............
_editprintablechar:
   cmp al, 20h
   jc _evalcursorpos
   cmp al, 7Ch
   jnc _evalcursorpos
   xtputchar ax
_evalcursorpos:
   mov dx, [_cursorpos]
   cmp dh, 1
   jnc _evalcursortopok
   test [viewoffset], 0FFFFh
   jz _notscrolleddn
   scrolldn 1, 0, 23, 79, 1, 7
   ;mov si, [_dskrdbuffer]
   ;add si, [viewoffset]
   ;xor cx, cx
_fetchprvline:
   ;dec si
   ;inc cx
   ;cmp cx, [viewoffset]
   ;jnc _prvlinefound
   ;cmp word [si-02], 0A0Dh
   ;jnz _fetchprvline
_prvlinefound:
   ;   mov [lastlinesz], cx
   ;push cx
   ;puttext 1, 0, si
      mov byte [rebufferflag], 3
   mov si, [_dskrdbuffer]
   add si, [viewoffset]
   add si, [visiblechars]
   xor cx, cx
_fetchprvvsb:
   dec si
   inc cx
   cmp cx, 80
   jz _prvvsbfound
   cmp word [si-02], 0A0Dh
   jnz _fetchprvvsb
_prvvsbfound:
   sub [visiblechars], cx
   ;pop cx
   ;add [visiblechars], cx
   ;sub [viewoffset], cx
_notscrolleddn:
   mov dh, 1
_evalcursortopok:
   cmp dh, 24
   jc _cursorevaluated
   mov si, [txtseek]
   add si, [viewoffset]
   add si, [visiblechars]
   cmp si, [_sysfiletable.size]
   jnc _notscrolledup
_loadnxtpart:
   scrollup 1, 0, 23, 79, 1, 7
   ;mov si, [viewoffset]
   ;add si, [visiblechars]
   ;add si, [_dskrdbuffer]
   ;puttext 23, 0, si
      mov byte [rebufferflag], 2
   ;   mov [lastlinesz], cx
   ;add si, cx
   ;cmp word [si], 0A0Dh
   ;jnz _notlinefeed
   ;add cx, 2
_notlinefeed:
   ;push cx
   xor cx, cx
   mov si, [viewoffset]
   add si, [_dskrdbuffer]
   jmp _schnxtline
_fetchnextline:
   inc si
   inc cx
_schnxtline:
   cmp cx, 80
   jnc _nxtlinefound
   cmp word [si], 0A0Dh
   jnz _fetchnextline
   add cx, 02
_nxtlinefound:
   add [viewoffset], cx
   sub [visiblechars], cx
_scuvwofsnotupdated:
   ;pop cx
   ;add [visiblechars], cx
_notscrolledup:
   mov dh, 23
_cursorevaluated:
   mov [_cursorpos], dx
   jmp loadtxtfile

txtdiskerror:
   puttext 24, 0, msgdskreaderror
   jmp exit
_filenotfound:
   puttext 24, 0, msgfilenotfound
exit:
   fileclose 1
   mov ax, 5048h
   cmp [_runmode], ax
   jnz exittodos
   retf
exittodos:
   int 20h

_dummyarea:

