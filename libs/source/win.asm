_putchr:
  ; input: al = character code
  ; config: int = 10, ah = 14, bh = page number (text mode), bl = foreground pixel (graphic mode)
  ret
  
  
_putline:
  ret
  
  
_putstr:
  ; input: offset, length
  ret 2 * REG_BYTE_SIZE
  
  
_print:
  ret 1 * REG_BYTE_SIZE
  
  
puts:
  ret 1 * REG_BYTE_SIZE
  
exit_process:
  ret
