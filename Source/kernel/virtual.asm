db 12h, 34h
dw end_of_block - block_begin

block_begin:

virtual
  align 16
  a = $ - $$
end virtual
db a dup 0
db 12h, 34h

end_of_block:
