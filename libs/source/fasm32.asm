use32

r_ax                      EQU eax
r_cx                      EQU ecx
r_dx                      EQU edx
r_bx                      EQU ebx
r_sp                      EQU esp
r_bp                      EQU ebp
r_si                      EQU esi
r_di                      EQU edi

REG_BYTE_SIZE             EQU 4
REG_DATA_SIZE             EQU dd
REG_SIZE_NAME             EQU dword
REG_SIZE_BITS             EQU 2

ARGUMENT1                 EQU 2 * REG_BYTE_SIZE
ARGUMENT2                 EQU 3 * REG_BYTE_SIZE
ARGUMENT3                 EQU 4 * REG_BYTE_SIZE
ARGUMENT4                 EQU 5 * REG_BYTE_SIZE
ARGUMENT5                 EQU 6 * REG_BYTE_SIZE

macro var [varargs] {dd varargs}
