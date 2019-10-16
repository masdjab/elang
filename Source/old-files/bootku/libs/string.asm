;STRING ROUTINES
_strfill:
   push bp
   mov bp, sp
   push ax
   push cx
   push di
   mov ax, [bp+4]
   xor cx, cx
   or cx, [bp+6]
   mov di, [bp+8]
   cld
   repnz
   stosb
   pop di
   pop cx
   pop ax
   pop bp
   ret 6

macro strfill dststring, strlength, fillerbyte
  {push dststring
   push strlength
   push fillerbyte
   call _strfill}

_cmpstring:
   push bp
   mov bp, sp
   push cx
   push si
   push di
   cld
   mov si, [bp+8]
   mov di, [bp+6]
   mov cx, [bp+4]
   test cx, cx
   jz _cmpzerostrlen
   push cx
   xor cx, cx
   pop cx
   repz
   cmpsb
_cmpzerostrlen:
   pop di
   pop si
   pop cx
   pop bp
   ret 6

_strinsertchr:
   push bp
   mov bp, sp
   push ax
   push cx
   push di
   mov di, [bp+8]
   add di, [bp+6]
   mov ax, [bp+4]
   mov [di], al
   pop di
   pop cx
   pop ax
   pop bp
   ret 6

macro strinsertchr srcstring, chroffset, chrvalue
  {push srcstring
   push chroffset
   push chrvalue
   call _strinsertchr}

_cmpzstring:
   push bp
   mov bp, sp
   push ax
   push si
   push di
   cld
   mov si, [bp+6]
   mov di, [bp+4]
_repcmpzstring:
   cmpsb
   jnz _cmpzstrend
   mov ah, [si-1]
   mov al, [di-1]
   cmp ah, 0
   jz _zstrzero
   cmp al, 0
   jz _zstrzero
   jmp _repcmpzstring
_zstrzero:
   cmp ah, al
   jz _cmpzstrend
   or al, 1
_cmpzstrend:
   pop di
   pop si
   pop ax
   pop bp
   ret 4

macro cmpstring strsource, strdest, strcount
  {push strsource
   push strdest
   push strcount
   call _cmpstring}
macro cmpzstring strsource, strdest
  {push strsource
   push strdest
   call _cmpzstring}

_strcopy:
   push bp
   mov bp, sp
   push cx
   push si
   push di
   cld
   mov si, [bp+8]
   mov di, [bp+6]
   mov cx, [bp+4]
   test cx, cx
   repnz
   movsb
   pop di
   pop si
   pop cx
   pop bp
   ret 6

macro strcopy strsource, strdest, strcount
  {push strsource
   push strdest
   push strcount
   call _strcopy}

_chkwhtspace:
   cmp al, 20h
   jz _whtspcevaluated
   cmp al, 9
_whtspcevaluated:
   ret

_chkdelimiter:
   cmp al, 0
   jz _dlmtrevaluated
   cmp al, '.'
   jz _dlmtrevaluated
   cmp al, ','
_dlmtrevaluated:
   ret

_getword:
   push bp
   mov bp, sp
   push si
   push di
   mov si, [bp+6]
   mov ax, [si]
   mov si, ax
   mov di, [bp+4]
   xor cx, cx
   cld
_getwordchknxtchr:
   ;lodsb
   mov al, [si]
   call _chkdelimiter
   jz _wdlendefined
   call _chkwhtspace
   jz _whtspcchars
_getwordvalidchar:
   or ch, 80h
   stosb
   inc cx
_gwfetchnxtchr:
   inc si
   jmp _getwordchknxtchr
_whtspcchars:
   test ch, 80h
   jz _gwfetchnxtchr
_wdlendefined:
   and ch, 7Fh
   push ax
   mov ax, si
   mov si, [bp+6]
   mov [si], ax
   pop ax
   pop di
   pop si
   pop bp
   ret 4

;macro getword {call _getword}
macro getword srcstring, dststring
  {push srcstring
   push dststring
   call _getword}
   ;AL = delimiter
   ;CX = string length

_getwordsize:
   push bp
   mov bp, sp
   push ax
   push si
   xor cx, cx
   mov si, [bp+4]
_chkcrtwdchar:
   mov al, 0
   cmp [si], al
   jz _wordretrieved
   mov al, 20h
   cmp [si], al
   jz _leadingspaces
   mov al, 9
   cmp [si], al
   jz _leadingspaces
   mov al, ','
   cmp [si], al
   jz _wordretrieved
   mov al, '.'
   cmp [si], al
   jz _wordretrieved
   or ch, 1
_getnxtwordchr:
   inc cl
   inc si
   jmp _chkcrtwdchar
_leadingspaces:
   test ch, ch
   jz _getnxtwordchr
_wordretrieved:
   test ch, ch
   jnz _wordlengthset
   xor cl, cl
_wordlengthset:
   xor ch, ch
   pop si
   pop ax
   pop bp
   ret 2

macro getwordsize stroffset
  {push stroffset
   call _getwordsize}

_cmpwdstring:
   push bp
   mov bp, sp
   push cx
   push dx
   push bx
   push si
   push di
   mov si, [bp+6]
   mov di, [bp+4]
   getwordsize si
   mov dx, cx
   getwordsize di
   mov bx, cx
   cmp dx, bx
   jnz _wdcompareok
   cmpstring si, di, cx
_wdcompareok:
   pop di
   pop si
   pop bx
   pop dx
   pop cx
   pop bp
   ret 4
macro cmpwdstring srcstring, dststring
  {push srcstring
   push dststring
   call _cmpwdstring}

_lowercase:
   push bp
   mov bp, sp
   push ax
   push cx
   push si
   push di
   pushf
   mov si, [bp+8]
   mov di, [bp+6]
   mov cx, [bp+4]
   test cx, cx
   jz _lwrquit
   cld
_replconvert:
   lodsb
   cmp al, 'A'
   jc _lnotconvert
   cmp al, 5Bh		;'Z' + 1
   jnc _lnotconvert
   add al, 20h
_lnotconvert:
   stosb
   loop _replconvert
_lwrquit:
   popf
   pop di
   pop si
   pop cx
   pop ax
   pop bp
   ret 6

_uppercase:
   push bp
   mov bp, sp
   push ax
   push cx
   push si
   push di
   pushf
   mov si, [bp+8]
   mov di, [bp+6]
   mov cx, [bp+4]
   test cx, cx
   jz _uprquit
   cld
_repuconvert:
   lodsb
   cmp al, 'a'
   jc _unotconvert
   cmp al, 7Bh		;'z' + 1
   jnc _unotconvert
   sub al, 20h
_unotconvert:
   stosb
   loop _repuconvert
_uprquit:
   popf
   pop di
   pop si
   pop cx
   pop ax
   pop bp
   ret 6

macro lcase srcstring, dststring, strlength
  {push srcstring
   push dststring
   push strlength
   call _lowercase}

macro ucase srcstring, dststring, strlength
  {push srcstring
   push dststring
   push strlength
   call _uppercase}

_ltrim:
   push bp
   mov bp, sp
   push ax
   push cx
   push si
   push di
   mov si, [bp+8]
   mov di, [bp+6]
   mov cx, [bp+4]
   xor ah, ah
   test cx, cx
   jz _ltrimnostring
   cld
_ltrimrepeat:
   lodsb
   test ah, ah
   jnz _ltrimchrcopy
   cmp al, 20h
   jz _ltrimchrcopied
   cmp al, 9
   jz _ltrimchrcopied
_ltrimchrcopy:
   stosb
   mov ah, 80h
_ltrimchrcopied:
   loop _ltrimrepeat
   xor al, al
   stosb
_ltrimnostring:
   pop di
   pop si
   pop cx
   pop ax
   pop bp
   ret 6

macro ltrim  srcstring, dststring, strlength
  {push srcstring
   push dststring
   push strlength
   call _ltrim}

_compressfilename:
_fncompress:
   push bp
   mov bp, sp
   push ax
   push cx
   push si
   push di
   mov si, [bp+6]
   mov di, [bp+4]
   getwordsize si
   cmp cx, 8
   jc _fmtshortfn
   mov cx, 8
_fmtshortfn:
   mov ax, 2Eh
   or al, al
   push si
   repnz
   movsb
   pop si
   add si, 8
   getwordsize si
   cmp cx, 3
   jc _fmtshortext
   mov cx, 3
_fmtshortext:
   test cx, cx
   jz _fmtfncopyok
   stosb
   or al, al
   repnz
   movsb
_fmtfncopyok:
   mov [di], ah
   pop di
   pop si
   pop cx
   pop ax
   pop bp
   ret 4

macro fncompress srcfn, dstfn
  {push srcfn
   push dstfn
   call _fncompress}

_decrypt:
   push bp
   mov bp, sp
   push ax
   push cx
   push bx
   push si
   push di
   mov si, [bp+8]
   mov di, [bp+6]
   mov ax, [bp+4]
   cld
   mov bl, 2
   div bl
   test ah, ah
   mov ah, al
   mov cx, 2
   jz _dcrloadpart
   inc al
_dcrloadpart:
   push cx
   push ax
   push si
   xor ah, ah
   mov cx, ax
_dcrloadchar:
   lodsb
   xor al, 0FFH
   stosb
   inc si
   loop _dcrloadchar
   pop si
   pop ax
   pop cx
   inc si
   xchg ah, al
   loop _dcrloadpart
   mov al, 0
   stosb
   pop di
   pop si
   pop bx
   pop cx
   pop ax
   pop bp
   ret 6

macro decrypt srcstring, dststring, strlength
  {push srcstring
   push dststring
   push strlength
   call _decrypt}

