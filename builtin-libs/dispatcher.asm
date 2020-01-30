org 100h

jmp main

obj_no_method:
  mov ax, 4001h
  ret
  
obj_wrong_args_count:
  mov ax, 4002h
  ret
  
obj_invalid_class_id:
  mov ax, 4003h
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
  mov ax, _dispatch_object_method_return_to_caller
  push ax
  
  push si
  mov si, [bp + 4]
  mov ax, [si]
  pop si
  ; get handler address based on object type and method id
  ; store the result in ax
  push ax
  ret
  
_dispatch_object_method_return_to_caller:
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
