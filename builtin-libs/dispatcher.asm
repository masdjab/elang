org 100h

jmp main

obj_no_method:
  mov ax, 4001h
  ret
  
obj_wrong_args_count:
  mov ax, 4002h
  ret
  
obj_method_1_1:
  ; args: 0
  mov ax, 8001h
  ret
  
obj_method_1_2:
  ; args: 1
  mov ax, 8002h
  ret
  
obj_method_2_1:
  ; args: 2
  mov ax, 8003h
  ret
  
obj_method_2_2:
  ; args: 3
  mov ax, 8004h
  ret
  
dispatch_obj_method:
  ; args: object, method-id, args-count, *args
  push bp
  mov bp, sp
  
  mov ax, _dom_method_executed
  push ax
  push dx
  mov ax, [bp + 6]
  cmp ax, 1
  mov dx, obj_method_1_1
  jz _dom_method_set
  cmp ax, 2
  mov dx, obj_method_1_2
  jz _dom_method_set
  cmp ax, 3
  mov dx, obj_method_2_1
  jz _dom_method_set
  cmp ax, 4
  mov dx, obj_method_2_2
  jz _dom_method_set
  mov dx, obj_no_method
_dom_method_set:
  xchg ax, dx
  pop dx
  push ax
  ret
  
_dom_method_executed:
  push ax
  push si
  mov si, bp
  mov ax, [bp + 8]
  add ax, 4
  shl ax, 1
  add si, ax
  mov ax, [bp + 2]
  xchg bp, si
  mov [bp], ax
  xchg bp, si
  mov [bp + 2], si
  pop si
  pop ax
  pop bp
  pop sp
  ret

main:
  mov dx, 100h
  mov bx, 33h
  
  mov ax, 1
  mov cx, 0
  push cx
  push ax
  push dx
  call dispatch_obj_method
  
  mov ax, 2
  mov cx, 1
  push bx
  push cx
  push ax
  push dx
  call dispatch_obj_method
  
  mov ax, 3
  mov cx, 2
  push bx
  push bx
  push cx
  push ax
  push dx
  call dispatch_obj_method
  
  mov ax, 4
  mov cx, 3
  push bx
  push bx
  push bx
  push cx
  push ax
  push dx
  call dispatch_obj_method
  
  mov ax, 5
  mov cx, 4
  push bx
  push bx
  push bx
  push bx
  push cx
  push ax
  push dx
  call dispatch_obj_method
  
  int 20h
