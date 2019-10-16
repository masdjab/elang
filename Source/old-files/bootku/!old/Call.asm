

org 100h
jmp begin

include 'INCLUDE\LOADALL.INC'
tmpword 	dw 0
workspace	dw 0

_reverse:
  push bp
  mov bp, sp
  push ax
  push di
  mov di, [bp+6]
  mov ax, [bp+4]
  xchg ah, al
  mov [di], ax
  pop di
  pop ax
  pop bp
  ret 4

macro reverse result, wordvalue
 {push result
  push wordvalue
  call _reverse}

begin:
  call _sysinit
  whex wordstrvalue, word [tmpword]
  print wordstrvalue
  forcelinefeed

  ;tmpword=reverse(5678)
  reverse tmpword, 5678h
     whex wordstrvalue, word [tmpword]
     print wordstrvalue
     forcelinefeed

  ;tmpword=reverse(reverse(1234))
  reverse tmpword, 1234h
  reverse tmpword, [tmpword]
  reverse tmpword, [tmpword]
     whex wordstrvalue, [tmpword]
     ;whex wordstrvalue, [workspace]
     print wordstrvalue
     forcelinefeed

  ;tmpword=reverse(reverse(reverse(3456)))

  int 20h


_dummyarea: