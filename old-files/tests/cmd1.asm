; $023e     => global variable #23e byval
; $$0a      => local variable #0a byval
; &$023e    => global variable #23e byref
; &$$0a     => local variable #0a byref
; @23e      => value at $023e
; @@0a      => value at $$0a
; __result  => return value

org 100h
jmp main

r_add:
  ; @@0++
  ; input: &var, imm
  push bp
  mov bp, sp
  push si
  mov si, [bp + 4]
  inc word [si]
  pop si
  pop bp
  ret 2
  
print:
  push bp
  mov bp, sp
  push ax
  push dx
  mov ah, 9
  mov dx, [bp + 4]
  int 21h
  pop dx
  pop ax
  pop bp
  ret 2
  
waitkey:
  push bp
  mov bp, sp
  push ax
  push si
  mov ah, 8
  int 21h
  mov si, [bp + 4]
  mov [si], al
  pop si
  pop ax
  pop bp
  ret 2
  
main:
  push reg_2
  call waitkey
  mov al, [reg_2]
  mov [reg_1], al
  push reg_0
  call print                ; putc &$1
  ;push reg_1
  ;call r_add               ; r_add &$1, 1
  ;inc word [reg_0]         ; @0++
  ;cmp word [reg_0], 5
  cmp byte [reg_2], 30h
  jnz main                  ; jeq @0, 5, -3
  int 20h
  
reg_0:      db 'Key '
reg_1:      db 0, ' pressed', 13, 10, '$'
reg_2:      dw 0
