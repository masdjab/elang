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

ARGUMENT1                 EQU 2 * REG_BYTE_SIZE
ARGUMENT2                 EQU 3 * REG_BYTE_SIZE
ARGUMENT3                 EQU 4 * REG_BYTE_SIZE
ARGUMENT4                 EQU 5 * REG_BYTE_SIZE
ARGUMENT5                 EQU 6 * REG_BYTE_SIZE

macro var [varargs] {dd varargs}
