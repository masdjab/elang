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


struc clsselection
{
   .s			dw 0
   .d			db 0
   .l			dw 0
}

struc clseditbox
{
   .y			db 1
   .x			db 0
   .yy			db 22
   .xx			db 80
   .clr 		db 7
   .bfr 		dw 0
   .len 		dw 0
}


_locate:
   push bp
   mov bp, sp
   push dx
   mov dl, byte [bp+4]
   mov dh, byte [bp+6]
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   pop dx
   pop bp
   ret 4

macro locate y, x
  {push y
   push x
   call _locate}

_setcolour:
   push bp
   mov bp, sp
   push ax
   push cx
   push dx
   push es
   push di
   mov cx, [bp+06]
   test cx, cx
   jz _stcnotpaint
   push [_cursorpos]
   mov dx, [bp+08]	;x
   mov ax, [bp+10]	;y
   mov dh, al
   mov [_cursorpos], dx
   call _setscrptr
   mov ax, 0B800h
   mov es, ax
   mov di, [_screenptr]
   mov ax, [bp+04]
_stcpaint:
   inc di
   stosb
   loop _stcpaint
   pop [_cursorpos]
   call _setscrptr
   call _cursorrfsh
_stcnotpaint:
   pop di
   pop es
   pop dx
   pop cx
   pop ax
   pop bp
   ret 8

macro setcolour y, x, xx, colour
  {push y
   push x
   push xx
   push colour
   call _setcolour}

_xtputchar:
   push bp
   mov bp, sp
   push ax
   push es
   push di
   mov ax, 0B800h
   mov es, ax
   mov di, [_screenptr]
   mov al, byte [bp+4]
   mov [es:di], al
   cursormove 0, 1
   pop di
   pop es
   pop ax
   pop bp
   ret 2

macro xtputchar character
  {push character
   call _xtputchar}

_puttext:
   push bp
   mov bp, sp
   push ax
   push dx
   push es
   push si
   push di
   mov dx, [_cursorpos]
   push dx
   mov dx, [bp+06]	;x
   mov ax, [bp+08]	;y
   mov dh, al
   mov [_cursorpos], dx
   call _setscrptr
   mov ax, 0B800h
   mov es, ax
   mov di, [_screenptr]
   mov si, [bp+04]	;stroffset
   xor cx, cx
   cld
_ptxtsndchar:
   lodsb
   test al, al
   jz _ptxtfinished
   cmp al, 13
   jz _ptxtfinished
   cmp al, 10
   jz _ptxtfinished
   stosb
   inc cx
   inc di
   inc dl
   cmp dl, 80
   jc _ptxtsndchar
_ptxtfinished:
   pop dx
   mov [_cursorpos], dx
   call _setscrptr
   call _cursorrfsh
   pop di
   pop si
   pop es
   pop dx
   pop ax
   pop bp
   ret 6

macro puttext y, x, stroffset
  {push y
   push x
   push stroffset
   call _puttext}

