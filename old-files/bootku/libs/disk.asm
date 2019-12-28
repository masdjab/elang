;DISK ROUTINES
_getdiskstatus:
   push ds
   push ax
   mov ax, 40h
   mov ds, ax
   pop ax
   mov al, [41h]
   test al, al
   pop ds
   ret

macro getdiskstatus {call _getdiskstatus}

_resetdisk:		;DL = drive number
   push ax
   push cx
   call _getdiskstatus
   jz _resetok
   mov cx, 7
   push cx
_resetretry:
   xor ah, ah
   int 13h
   pop cx
   jnc _resetok
   loop _resetretry
_resetok:
   pop cx
   pop ax
   ret			;Carry=1 if error

_setths:
   ;AX=absolute sector, CH=track, DH=head, CL=sector
   push ax
   push bx
   mov bx, 24h
   div bl
   mov ch, al
   mov bx, 12h
   xchg ah, al
   xor ah, ah
   div bl
   mov dh, al
   mov cl, ah
   inc cl
   pop bx
   pop ax
   ret

_readsector:
   ;10-buffer, 8-drive, 6-absolute sector, 4-sectors
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push bx
   mov bx, [bp+10]	;buffer
   mov dx, [bp+06]   ;absolute sector
   mov cx, [bp+04]   ;sectors
_loadnextsector:
   push cx
   push dx
   mov cx, 5
_loadsectorretry:
   push cx
   mov ax, dx
   call _setths
   mov ax, [bp+08]
   mov dl, al		;drive
   mov ax, 0201h
   int 13h
   pop cx
   jnc _readsectorok
   call _resetdisk
   loop _loadsectorretry
_readsectorok:
   pop dx
   pop cx
   add bx, 200h
   inc dx
   loop _loadnextsector
   pop bx
   pop dx
   pop cx
   pop ax
   pop bp
   ret 8

   ;return:
   ;NoCarry --> AH = 0, Success
   ;Carry   --> AH = Disk Error Code
   ;Sector: 1 - 8   for floppy
   ;        1 - 80H for harddisk
   ;        Harddisk Read/Write Long 1 - 79H
   ;        ES:BX = Buffer address for read/write
   ;For harddisk, DL = drive number (80H - 87H)
   ;              CH = cylinder (greater than 255)

macro readsector buffer, drive, sector, sectors
  {push buffer
   push drive
   push sector
   push sectors
   call _readsector}

_writesector:
   ;10-buffer, 8-drive, 6-sector, 4-sectors
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push bx
   mov dx, [bp+06]   ;absolute sector
   mov cx, [bp+04]   ;sectors
_writenextsector:
   push cx
   push dx
_writesectorretry:
   mov bx, [bp+10]	;buffer
   mov ax, dx
   call _setths
   mov ax, [bp+08]
   mov dl, al		;drive
   mov ax, 0301h
   int 13h
_writesectorok:
   pop dx
   pop cx
   inc dx
   loop _writenextsector
   pop bx
   pop dx
   pop cx
   pop ax
   pop bp
   ret 8

macro writesector buffer, drive, sector, sectors
  {push buffer
   push drive
   push sector
   push sectors
   call _writesector}

_resetsearch:
   push ax
   mov ax, 0
   mov [_crtschofs], ax
   mov [_crtschstt], al
   mov [_crtentry], al
   mov ax, 12h
   mov [_crtdirsct], ax
   pop ax
   ret

macro resetsearch {call _resetsearch}

_findfile:
   push bp
   mov bp, sp
   push ax
   push cx
   push es
   push si
   push di
   mov ax, [_syssegment]
   mov es, ax
   mov si, [_crtschofs]
   cmp [_crtentry], 10h 	;entries per sector
   jnc _usenextsector
_usecrtsector:
   add si, 20h
   test [_crtschstt], 10h
   jnz _checknextentry
_usenextsector:
   mov ax, [_crtdirsct]
   inc ax
   readsector [_mainsctbuffer], 0, ax, 1
   inc [_crtdirsct]
   mov si, [_mainsctbuffer]
   mov [_crtentry], 0
_checknextentry:
   mov al, 0
   cmp [si], al
   jz _fndnomorefound
   mov al, 0E5h
   cmp [si], al
   jz _crtfilebypassed
   mov al, 255
   cmp [si], al
   jz _crtfilebypassed
   mov al, 0Fh
   cmp [si+0Bh], al
   jz _crtfilebypassed
   mov al, 28h
   cmp [si+0Bh], al
   jz _crtfilebypassed
   mov ax, [bp+04]
   mov ah, [si+0Bh]
   and ah, al
   cmp ah, al
   jnz _crtfilebypassed
   xor al, al
   clc
   mov al, FNDFOUND
   jmp _fndevaluated
_fndnomorefound:
   xor al, al
   or al, FNDNOTFOUND
   jmp _fndevaluated
_crtfilebypassed:
   xor al, al
   stc
   mov al, FNDBYPASS
_fndevaluated:
   mov [_crtschstt], al
   mov [_crtschofs], si
   pushf
   inc [_crtentry]
   popf
   pop di
   pop si
   pop es
   pop cx
   pop ax
   pop bp
   ret 2

macro findfile schattribute
  {push schattribute
   call _findfile}

_loadfat:
   push bx
   mov ax, dx		;DX=cluster number
   mov bx, 03
   mul bx
   mov bx, 02
   div bx
   xor dx, dx
   mov bx, 200h
   div bx
   xor ah, ah
   add ax, 01		;AX=sector, DX=offset
   cmp [_crtfatsct], ax
   jz _rdfatbypassed
   mov [_crtfatsct], ax
   readsector [_mainfatbuffer], 0, ax, 2
_rdfatbypassed:
   pop bx
   ret

_getcluster:	    ;dx=current cluster
   push ax
   push cx
   push es
   push si
   mov ax, [_syssegment]
   mov es, ax
   push dx
   call _loadfat
_entryusecrtfatsector:
   mov si, [_mainfatbuffer]
   add si, dx
   mov cx, [si]
_clusterretrieved:
   pop dx
   test dx, 1
   jz _gclsuselwrbits
_gclsuseuprbits:
   shr cx, 4
   jmp _gclusterfound
_gclsuselwrbits:
   and cx, 0FFFh
_gclusterfound:
   mov dx, cx
   pop si
   pop es
   pop cx
   pop ax
   ret

_setcluster:
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push es
   mov ax, [_syssegment]
   mov es, ax
   mov dx, [bp+6]	;cluster number
   call _loadfat
   mov si, [_mainfatbuffer]
   add si, dx
   mov cx, [si]
   mov ax, [bp+6]
   test ax, 1
   mov ax, [bp+4]
   jz _sclsuselwrbits
_sclsuseuprbits:
   and cx, 000Fh
   shl ax, 4
   jmp _sclsmerged
_sclsuselwrbits:
   and cx, 0F000h
_sclsmerged:
   or cx, ax
   mov [si], cx
   mov ax, [_crtfatsct]
   writesector [_mainfatbuffer], 0, ax, 2
   pop es
   pop dx
   pop cx
   pop ax
   pop bp
   ret 4

macro setcluster clusternbr, clusterval
  {push clusternbr
   push clusterval
   call _setcluster}

_loadfile:
   push bp
   mov bp, sp
   push ax
   push dx
   push es
   push si
   push di
   mov ax, [bp+08]			;dstseg
   mov es, ax
   mov di, [bp+06]			;dstofs
   mov bx, 02				;first fat index
   mov si, [bp+10]			;dtaoffset
   mov dx, [si+26]			;first cluster
   xor cx, cx
_loadclusters:
   push dx
   add dx, 1Fh
   readsector di, 0, dx, 1
   inc cx
   add di, 200h
   pop dx
   cmp word [bp+04], 0
   jz _loadallsectors
   cmp cx, [bp+04]
   jnc _filesectorsloaded
_loadallsectors:
   call _getcluster
   cmp dx, 0FFFh
   jnz _loadclusters
_filesectorsloaded:
   mov cx, [si+28]			;file size
   pop di
   pop si
   pop es
   pop dx
   pop ax
   pop bp
   ret 8

macro loadfile dtaoffset, dstseg, dstofs, sectors
  {push dtaoffset
   push dstseg
   push dstofs
   push sectors
   call _loadfile}

_newfile:
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push bx
   cld
   mov ax, 2
   jmp _nfgetcluster
_nfthrowbestcluster:
   xor cx, cx
_nftstnxtcluster:
   inc ax
_nfgetcluster:
   cmp ax, 0B21h
   jnc _nflastcluster
   mov dx, ax
   call _getcluster
   test dx, dx
   jnz _nfthrowbestcluster
   test cx, cx
   jnz _nfbestclusterdefined
   mov cx, ax
_nfbestclusterdefined:
   test bx, bx
   jnz _nfworstclusterdefined
   mov bx, ax
_nfworstclusterdefined:
   jmp _nftstnxtcluster
_nflastcluster:
   test cx, cx
   jz _nfuseworstcluster
_nfusebestcluster:
   mov ax, cx
   jmp _nfclusterfound
_nfuseworstcluster:
   test bx, bx
   stc
   jz _nfexit
   mov ax, bx
_nfclusterfound:
   push ax
   add ax, 1Fh
   mov bx, [bp+6]
   writesector bx, 0, ax, 1
   pop ax
   setcluster ax, 0FFFh 	;only 1 sector!!!
   resetsearch
_nfschfreeentry:
   findfile 0
   jz _nfschfreeentry
   mov si, [_crtschofs]
   mov di, [bp+8]
   strcopy di, si, 11
   mov [si+1Ah], ax
   mov ax, [bp+4]
   mov [si+1Ch], ax
   mov al, 20h
   mov [si+0Bh], al
   mov ax, [_crtdirsct]
   writesector [_mainsctbuffer], 0, ax, 1
   clc
_nfexit:
   pop bx
   pop dx
   pop cx
   pop ax
   pop bp
   ret 6

macro newfile newfilename, strbuffer, strlength
  {push newfilename
   push strbuffer
   push strlength
   call _newfile}

_delete:
   push bp
   mov bp, sp
   push ax
   push cx
   push si
   resetsearch
_delfindfile:
   findfile 0
   jnz _delexit
   jc _delfindfile
   mov si, [_crtschofs]
   cmpstring word [bp+4], si, 11
   jnz _delfindfile
   mov al, 0E5h
   mov si, [_crtschofs]
   mov [si], al
   mov ax, [_crtdirsct]
   writesector [_mainsctbuffer], 0, ax, 1
   mov dx, [si+1Ah]
_delfreeclusters:
   mov ax, dx
   call _getcluster
   setcluster ax, 0
   cmp dx, 0FFFh
   jnz _delfreeclusters
   xor al, al
   jmp _delexit
_delexit:
   pop si
   pop cx
   pop ax
   pop bp
   ret 2

macro delete delfilename
  {push delfilename
   call _delete}

_fileseek:
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push bx
   mov byte [_sysfiletable.eof], 0
   mov ax, [bp+04]
   cmp ax, [_sysfiletable.size]
   jnc _seekendoffile
   test [_sysfiletable.crtcluster], 0FFFFh
   jz _seekonopen
   cmp [_sysfiletable.seek], ax
   jz _seeknotmoved
_seekonopen:
   mov [_sysfiletable.seek], ax
   mov bx, 200h
   xor dx, dx
   div bx
   mov [_sysfiletable.rdoffset], dx
   mov cx, ax
   test word [_sysfiletable.crtcluster], 0FFFFh
   jz _seeknotcrtcluster
   cmp cx, [_sysfiletable.clusternbr]
   jz _seeknotmoved
_seeknotcrtcluster:
   mov [_sysfiletable.clusternbr], ax
   mov dx, [_sysfiletable.clst]
   test cx, cx
   jz _seekclstfound
_seekschclst:
   call _getcluster
   cmp dx, 0FFFh
   jz _seekclstfound
   loop _seekschclst
_seekclstfound:
   add dx, 1Fh
   readsector [_sysfiletable.buffer], 0, dx, 1
   mov [_sysfiletable.crtcluster], dx
   mov ax, [_sysfiletable.seek]
   cmp ax, [_sysfiletable.size]
   jc _seeknotmoved
_seekendoffile:
   mov ax, [_sysfiletable.size]
   mov [_sysfiletable.seek], ax
   mov byte [_sysfiletable.eof], 1
_seeknotmoved:
   pop bx
   pop dx
   pop cx
   pop ax
   pop bp
   ret 4

macro fileseek filehandle, byteoffset
  {push filehandle
   push byteoffset
   call _fileseek}

_fileopen:
   push bp
   mov bp, sp
   push ax
   push dx
   push bx
   push si
   push di
   resetsearch
_fopnschfile:
   findfile 0
   jnz _fopnnotfound
   jc _fopnschfile
   cmpstring [_crtschofs], word [bp+06], 11
   jnz _fopnschfile
   strcopy [_crtschofs], _sysfiletable, 20h
   mov word [_sysfiletable.crtcluster], 0
   mov word [_sysfiletable.nxtcluster], 0
   mov word [_sysfiletable.rdcapacity], 1
   mov byte [_sysfiletable.used], 1
   mov byte [_sysfiletable.eof], 0
   fileseek 1, 0
   clc
   jmp _fopnexit
_fopnnotfound:
   stc
_fopnexit:
   pop di
   pop si
   pop bx
   pop dx
   pop ax
   pop bp
   ret 4

macro fileopen openfilename, openfilehandle
  {push openfilename
   push openfilehandle
   call _fileopen}

_fileclose:
   push bp
   mov bp, sp
   mov byte [_sysfiletable.used], 0
   pop bp
   ret 2

macro fileclose filehandle
  {push filehandle
   call _fileclose}


_fileread:
   push bp
   mov bp, sp
   push ax
   push cx
   push si
   push di

   mov di, [bp+06]
   mov cx, [bp+04]
_frdgetnxtcluster:
   push cx
   mov ax, 200h
   cmp cx, ax
   jc _frdcxcutbysector
   mov cx, ax			;cx <= sector limit
_frdcxcutbysector:
   sub ax, [_sysfiletable.rdoffset]   ;ax = max allowed read length
   cmp cx, ax
   jc _frdcxcutbylen
   mov cx, ax
_frdcxcutbylen:
   mov ax, [_sysfiletable.size]
   sub ax, [_sysfiletable.seek]
   cmp cx, ax
   jc _frdcxcutbyeof
   mov cx, ax			;cx <= file size
_frdcxcutbyeof:
   mov si, [_sysfiletable.buffer]
   add si, [_sysfiletable.rdoffset]
   strcopy si, di, cx
   add di, cx
   mov ax, cx
   add cx, [_sysfiletable.seek]
   fileseek 1, cx
   pop cx
   test byte [_sysfiletable.eof], 0FFh
   jnz _filereadexit
   sub cx, ax
   jnz _frdgetnxtcluster
_filereadexit:
   pop di
   pop si
   pop cx
   pop ax
   pop bp
   ret 6

macro fileread frdhandle, frdbuffer, frdlength
  {push frdhandle
   push frdbuffer
   push frdlength
   call _fileread}

macro chkeof {test byte [_sysfiletable.eof], 0FFh}

