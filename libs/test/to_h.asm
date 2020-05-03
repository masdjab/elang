org 100h

jmp main

_nible_to_h:
  ; input: al; output: al
  and al, 0fh
  add al, 30h
  cmp al, 3ah
  jc _nible_to_h_done
  add al, 7
_nible_to_h_done:
  ret
  
  
_byte_to_h:
  ; input: al; output: ax
  mov ah, al
  call _nible_to_h
  xchg ah, al
  shr al, 4
  call _nible_to_h
  xchg ah, al
  ret
  
main:
  mov ax, 8
  call _nible_to_h
  mov ax, 10
  call _nible_to_h
  mov ax, 34h
  call _byte_to_h
  int 20h
