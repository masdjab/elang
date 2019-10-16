_creatememtable:
   push ax
   push dx
   push bx
   mov ax, maxmemhandles	;Allocate entries for memory allocation table.
   mov bx, 3			;Each of entry has 3 word, these words represent
   xor dx, dx			;start address or pointer to memory block location,
   mul bx			;length of memory block, and memory block status.
   cmp [_heapsize], ax
   jc _creatememexit
   mov dx, [_freeheap]
   mov [memalloctable], dx
   add word [_freeheap], ax
   sub word [_heapsize], ax
   clc
_creatememexit:
   pop bx
   pop dx
   pop ax
   ret

_memalloc:
   push bp
   mov bp, sp
   push ax
   push dx
   push bx
   push si
   mov ax, maxmemhandles
   cmp [freememhandle], ax
   jnc _memallocfail
   mov si, [memalloctable]
   xor dx, dx
   mov bx, 3
   mov ax, [freememhandle]
   mul bx
   add si, ax			;ax = size of memory block entry
   mov bx, [_freeheap]
   mov [si+00], bx		;pointer to memory block
   mov ax, [bp+04]
   mov [si+02], ax		;size of memory block
   add [_freeheap], ax
   sub [_heapsize], ax
   mov word [si+04], 1		;this memory block is currently used
   inc word [freememhandle]	;set next free memory block handle
   mov si, [bp+06]
   mov [si], bx 		;return pointer value to memory block
   clc
   jmp _memallocexit
_memallocfail:
   stc
_memallocexit:
   pop si
   pop bx
   pop dx
   pop ax
   pop bp
   ret 4

macro memalloc memoffset, memsize
  {push memoffset
   push memsize
   call _memalloc}


mainfatbuffersize	equ 400h
mainsctbuffersize	equ 200h
dskrdbuffersize 	equ 800h
dskwrbuffersize 	equ 800h
spacetolerance		equ 10h


_sysinit:
   push ax
   mov ax, cs
   mov [_syssegment], ax
   mov ax, _dummyarea
   and ax, 0FF00h
   add ax, 100h
   mov [_mainfatbuffer], ax
   add ax, mainfatbuffersize
   mov [_mainsctbuffer], ax
   add ax, mainsctbuffersize
   ;add ax, spacetolerance
   mov [_dskrdbuffer], ax
   add ax, dskrdbuffersize
   ;add ax, spacetolerance
   mov [_dskwrbuffer], ax
   add ax, dskwrbuffersize
   ;add ax, spacetolerance
   mov [_freeheap], ax
   mov ax, 0FFFFh
   sub ax, [_freeheap]
   inc ax
   mov [_heapsize], ax
   mov [_runmode], dx
   call _creatememtable
   memalloc _sysfiletable.buffer, 200h
   pop ax
   ret


