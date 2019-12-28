_creatememtable:
   push ax
   push dx
   mov ax, maxmemhandles
   shl ax, 1
   cmp [_heapsize], ax
   jc _creatememexit
   mov dx, [_freeheap]
   mov [memalloctable], dx
   add word [_freeheap], ax
   sub word [_heapsize], ax
   clc
_creatememexit:
   pop dx
   pop ax
   ret

_memalloc:
   push bp
   mov bp, sp
   push ax
   push bx
   push si
   mov ax, maxmemhandles
   cmp [freememhandle], ax
   jnc _memallocfail
   mov si, [memalloctable]
   mov bx, [freememhandle]
   inc bx
   push bx
   shl bx, 1
   add si, bx
   mov ax, [_freeheap]
   mov [si+00], ax
   mov ax, [bp+06]
   mov [si+02], ax
   add [_freeheap], ax
   sub [_heapsize], ax
   pop bx
   mov si, [bp+04]
   mov [si], bx
   mov [freememhandle], bx
   clc
   jmp _memallocexit
_memallocfail:
   stc
_memallocexit:
   pop si
   pop bx
   pop ax
   pop bp
   ret 4

macro memalloc memsize, memhandle
  {push memsize
   push memhandle
   call _memalloc}
