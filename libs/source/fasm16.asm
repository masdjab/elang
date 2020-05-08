use16

r_ax                      EQU ax
r_cx                      EQU cx
r_dx                      EQU dx
r_bx                      EQU bx
r_sp                      EQU sp
r_bp                      EQU bp
r_si                      EQU si
r_di                      EQU di

REG_BYTE_SIZE             EQU 2
REG_DATA_SIZE             EQU dw
REG_SIZE_NAME             EQU word
REG_SIZE_BITS             EQU 1

macro var [varargs] {dd varargs}
