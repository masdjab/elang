; CONVERSION ROUTINES
; _hexnib, _hexbyte, _hex, hex

_hexnib:
  and al, 15
  cmp al, 10
  jnc _nibletter
  add al, 30h
  jmp _nibok
_nibletter:
  add ax, 37h
_nibok:
  ret
  
_hexbyte:
  mov ah, al
  call _hexnib
  xchg ah, al
  shr al, 4
  call _hexnib
  ret
  
bhex:
  ; input : args(value)
  ; output: ax
  push bp
  mov bp, sp
  ; mov ax, [bp+04]
  mov al, [bp+04]
  call _hexbyte
  pop bp
  ret 2
  
whex:
  ; input : args(value)
  ; output: dx:ax
  push bp
  mov bp, sp
  mov ax, [bp+4]
  push ax
  xchg ah, al
  call _hexbyte
  mov dx, ax
  pop ax
  call _hexbyte
  pop bp
  ret 2
  
  
_nval:
  cmp al, 30h
  jc _nvalinvalid
  cmp al, 3Ah
  jnc _nvaluprcase
_ndecvalue:
  and al, 15
  jmp _nvalok
_nvaluprcase:
  cmp al, 41h
  jc _nvalinvalid
  cmp al, 47h
  jc _nvalhexok
_nvallwrcase:
  cmp al, 61h
  jc _nvalinvalid
  cmp al, 67h
  jnc _nvalinvalid
_nvalhexok:
  and al, 7
  add al, 9
  clc			;CF=0, OK
  jmp _nvalok
_nvalinvalid:
  xor al, al
  stc			;CF=1, invalid
_nvalok:
  ret
  
; _bval:
byte_to_i:
  ; input : args(value)
  ; output: al
  push bp
  mov bp, sp
  mov ax, [bp + 4]
  call _nval
  xchg ah, al
  call _nval
  shl al, 4
  or al, ah
  xor ah, ah
  pop bp
  ret 2
  
_decstr:
  push bp
  mov bp, sp
  push ax
  push cx
  push dx
  push bx
  push si
  push di
  mov di, [bp+6]
  mov ax, [bp+4]
  mov si, di
  mov bx, 10
  xor cx, cx
  cld
_decloop:
  xor dx, dx
  div bx
  add dl, 30h
  mov [di], dl
  inc di
  inc cx
  test ax, ax
  jnz _decloop
  mov al, 0
  mov [di], al
  dec di
  mov ch, cl
  and ch, 1
  shr cl, 1
  add cl, ch
  xor ch, ch
_decstrrevert:
  mov ah, [si]
  mov al, [di]
  mov [di], ah
  mov [si], al
  inc si
  dec di
  loop _decstrrevert
  pop di
  pop si
  pop bx
  pop dx
  pop cx
  pop ax
  pop bp
  ret 4
  
macro decstr stroffset, hvalue
  {push stroffset
   push hvalue
   call _decstr}
