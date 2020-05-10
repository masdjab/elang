_putchr:
_putline:
_putstr:
_print:
  ret
  
puts:
  ; input: str object
  ret 1 * REG_BYTE_SIZE
  
  
exit_process:
  ret
