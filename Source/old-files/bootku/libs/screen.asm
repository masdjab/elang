;SCREEN ROUTINES:
;  _setscrptr, _movecursorleft, _movecursorright, _forcelinefeed, _cursorrfsh
;  _scrollup, _getcursor, _setcursor, _putchr, _print, _printline

_scrollup:
   push bp
   mov bp, sp
   push ax
   mov ah, 06
   jmp _scroll
_scrolldn:
   push bp
   mov bp, sp
   push ax
   mov ah, 07
_scroll:
   push cx
   push dx
   push bx
   mov ch, byte [bp+14]
   mov cl, byte [bp+12]
   mov dh, byte [bp+10]
   mov dl, byte [bp+08]
   mov al, byte [bp+06]
   mov bh, byte [bp+04]
   int 10h
   pop bx
   pop dx
   pop cx
   pop ax
   pop bp
   ret 12

macro scrollup y, x, yyy, xxx, yy, attr
  {push y
   push x
   push yyy
   push xxx
   push yy
   push attr
   call _scrollup}

macro scrolldn y, x, yyy, xxx, yy, attr
  {push y
   push x
   push yyy
   push xxx
   push yy
   push attr
   call _scrolldn}

_setscrptr:
   push ax
   push dx
   push di
   mov dx, [_cursorpos]       ;dx=0310
   xor ah, ah
   mov al, 80
   mul dh
   add al, dl
   jnc _setscrptrhcy
   inc ah
_setscrptrhcy:
   mov di, 02
   mul di
   mov di, ax
   mov [_screenptr], di
   pop di
   pop dx
   pop ax
   ret

_movecursorleft:
   push dx
   mov dx, [_cursorpos]
   dec dl
   call _chkcursorrange
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   pop dx
   ret

_movecursorright:
   push dx
   mov dx, [_cursorpos]
   inc dl
   call _chkcursorrange
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   pop dx
   ret

_chkcursorrange:
   test dl, 80h
   jz _cursorleftok
   mov dl, 79
   dec dh
   jmp _cursorrightok
_cursorleftok:
   cmp dl, 80
   jc _cursorrightok
   xor dl, dl
   inc dh
_cursorrightok:
   test dh, 80h
   jz _cursortopok
   xor dh, dh
   jmp _cursorbtmok
_cursortopok:
   cmp dh, 25
   jc _cursorbtmok
   ;call _scrollup
   scrollup 0, 0, 24, 79, 1, 7
   mov dh, 24
_cursorbtmok:
   ret

_forcelinefeed:
   push dx
   mov dx, [_cursorpos]
   xor dl, dl
   inc dh
_scrolledup:
   call _chkcursorrange
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   pop dx
   ret

macro forcelinefeed {call _forcelinefeed}

_cursorrfsh:
   push dx
   mov dx, [_cursorpos]
   call _setcursor
   pop dx
   ret

_cursormove:
   push bp
   mov bp, sp
   push ax
   push dx
   mov dx, [_cursorpos]
   mov al, byte [bp+4]
   mov ah, byte [bp+6]
   add dh, ah
   add dl, al
   test dl, 80h
   jz _csrcollftok
   mov dl, 79
   dec dh
_csrcollftok:
   cmp dl, 80
   jc _csrcolrgtok
   xor dl, dl
   inc dh
_csrcolrgtok:
   test dh, 80h
   jz _csrrowtopok
   xor dh, dh
_csrrowtopok:
   cmp dh, 25
   jc _csrrowbtmok
   mov dh, 24
_csrrowbtmok:
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   pop dx
   pop ax
   pop bp
   ret 4

macro cursormove yrel, xrel
  {push yrel
   push xrel
   call _cursormove}

_cls:
   push ax
   push cx
   push dx
   push bx
   mov ax, 0619h
   mov cx, 0
   mov dx, 1950h
   mov bh, _dftscrclr
   int 10h
   xor dx, dx
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   pop bx
   pop dx
   pop cx
   pop ax
   ret

macro clearscreen {call _cls}

_getcursor:
   ;bh = page number
   ;dh, dl = row, column
   push ax
   push cx
   push dx
   push bx
   xor bh, bh
   mov ah, 3
   int 10h
   mov [_cursorpos], dx
   call _setscrptr
   pop bx
   pop dx
   pop cx
   pop ax
   ret
   ;return: DH, DL = row, column of cursor position
   ;        CH, CL = cursor start, end
macro getcursor {call _getcursor}

_setcursor:
   ;input: dx = cursor pos
   ;bh     = page number
   ;dh, dl = row, column
   ;ch, cl = cursor start, end
   push ax
   push cx
   push bx
_noscroll:
   xor bh, bh
   mov ch, 6
   mov cl, 7
   mov ah, 2
   int 10h
   pop bx
   pop cx
   pop ax
   ret
macro setcursor
   {call _setcursor}

_putchr:
   push bp
   mov bp, sp
   push ax
   push es
   push di
   cld
   mov ax, 0b800h
   mov es, ax
   mov di, [_screenptr]
   mov ax, [bp+04]
   mov ah, _dftscrclr
   stosw
   call _movecursorright
   pop di
   pop es
   pop ax
   pop bp
   ret 2

_print:
   push bp
   mov bp, sp
   push ax
   push dx
   push si
   push di
   push es
   cld
   mov ax, 0b800h
   mov es, ax
   mov si, [bp+04]
   mov ah, _dftscrclr
   mov dx, [_cursorpos]
   mov di, [_screenptr]
_printloop:
   lodsb
   cmp al, 0
   jz _loopend
   cmp al, 13
   jz _prnmovehome
   cmp al, 10
   jz _prnlinefeed
   stosw
   call _movecursorright
   mov di, [_screenptr]
   jmp _cursormoved
_prnmovehome:
   mov dx, [_cursorpos]
   xor dl, dl
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   mov di, [_screenptr]
   jmp _printloop
_prnlinefeed:
   mov dx, [_cursorpos]
   inc dh
   call _chkcursorrange
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   mov di, [_screenptr]
   jmp _printloop
_cursormoved:
   jmp _printloop
_loopend:
   call _cursorrfsh
   pop es
   pop di
   pop si
   pop dx
   pop ax
   pop bp
   ret 02

_printline:
   ;this routine may be deleted since println
   ;can be performed by print "...",13,10,0
   push bp
   mov bp, sp
   push ax
   push dx
   getcursor
   push dx
   mov ax, [bp+04]
   push ax
   call _print
   pop dx
   xor dl, dl
   inc dh
   setcursor
   pop dx
   pop ax
   pop bp
   ret 02

macro putchar character
  {push character
   call _putchr}
macro print stroffset
  {push stroffset
   call _print}

macro println stroffset
  {push stroffset
   call _printline}

