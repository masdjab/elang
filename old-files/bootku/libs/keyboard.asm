;KEYBOARD ROUTINES
;  _readkey, _input
macro readkey
  {mov ah, 10h
   int 16h}

_input:
   push bp
   mov bp, sp
   push di
   xor cx, cx
   mov di, [bp+4]
_inputloop:
   readkey
   cmp al, 13
   jz _inputexit
   cmp al, 27
   jz _inputexit
   cmp al, 08
   jnz _showkeycode
   cmp cx, 0
   jz _inputloop
   call _movecursorleft
   dec di
   dec cx
   push ax
   mov al, 20h
   mov [di], al
   putchar ax
   pop ax
   call _movecursorleft
   jmp _inputloop
_showkeycode:
   mov [di], al
   inc di
   inc cx
   putchar ax
   jmp _inputloop
_inputexit:
   mov ah, 0
   mov [di], ah
   pop di
   pop bp		       ;AL = last key pressed
   ret 2
macro input strbuffer
  {push strbuffer
   call _input}

