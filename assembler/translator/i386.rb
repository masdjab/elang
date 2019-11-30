module Assembler
  class I386Translator < BaseTranslator
    private
    def as_obj(v)
      as_word(v)
    end
    def as_adr(v)
      as_word(v)
    end
    
    public
    def cmd_nop
      0x90.chr
    end
    def cmd_putarg(obj)
      # push obj
      0x68.chr + as_obj(obj)
    end
    def cmd_getarg(nn)
      # mov ax, [bp + (4 + nn * 2)]
      0x8b.chr + 0x46.chr + (4 + nn * 2).chr
    end
    def cmd_putb(adr)
      # copy byte from accumulator to memory
      # mov [addr], al
      0xa2.chr + as_adr(obj)
    end
    def cmd_getb(adr)
      # copy byte from memory to accumulator
      # mov al, [addr]
      0xa0.chr + as_adr(adr)
    end
    def cmd_putw(adr)
      # copy word from accumulator to memory
      # mov [addr], ax
      0xa3.chr + as_adr(obj)
    end
    def cmd_getw(adr)
      # copy word from memory to accumulator
      # mov ax, [addr]
      0xa1.chr + as_adr(adr)
    end
    def cmd_lput(index)
      # mov [bp - (2 + (index * 2))], ax
      0x89.chr + 0x46.chr + as_byte(2 + (index * 2))
    end
    def cmd_lget(index)
      # mov ax, [bp - (2 + (index * 2))]
      0x8b.chr + 0x46.chr + as_byte(2 + (index * 2))
    end
    def cmd_enter(nn)
      # enter (2 * nn), 0
      0xc8.chr + as_word(2 * nn) + 0x00.chr
    end
    def cmd_leave(nn)
      # leave
      0xc9.chr
    end
    def cmd_call(rel)
      # relative call
      # call rel
      0xe8.chr + as_word(rel)
    end
    def cmd_rjmp(rel)
      # relative jump
      # jmp rel
      0xe9.chr + as_word(rel)
    end
    def cmd_ajmp(adr)
      # absolute jump (converted to relative jump)
      # jmp rel
      0xe8.chr + as_adr(adr)
    end
    def cmd_is_null
      # 0x10.chr
      raise "Command 'is_null' not implemented."
    end
    def cmd_is_eq
      # pop cx
      # pop ax
      # cmp ax, cx
      # mov ax, _true
      # jz pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x59, 0x58, 0x39, 0xc8, 0xb8, 0xff, 0xff, 0x74, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_gt
      # pop cx
      # pop ax
      # cmp ax, cx
      # mov ax, _true
      # jg pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x59, 0x58, 0x39, 0xc8, 0xb8, 0xff, 0xff, 0x7f, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_lt
      # pop cx
      # pop ax
      # cmp ax, cx
      # mov ax, _true
      # jl pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x59, 0x58, 0x39, 0xc8, 0xb8, 0xff, 0xff, 0x7c, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_ge
      # pop cx
      # pop ax
      # cmp ax, cx
      # mov ax, _true
      # jge pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x59, 0x58, 0x39, 0xc8, 0xb8, 0xff, 0xff, 0x7d, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_le
      # pop cx
      # pop ax
      # cmp ax, cx
      # mov ax, _true
      # jle pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x59, 0x58, 0x39, 0xc8, 0xb8, 0xff, 0xff, 0x7e, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_ne
      # pop cx
      # pop ax
      # cmp ax, cx
      # mov ax, _true
      # jnz pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x59, 0x58, 0x39, 0xc8, 0xb8, 0xff, 0xff, 0x75, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_not
      # pop ax
      # test ax, ax
      # mov ax, _true
      # jz pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x58, 0x85, 0xc0, 0xb8, 0xff, 0xff, 0x74, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_and
      # pop cx
      # pop ax
      # test ax, ax
      # mov ax, _true
      # jnz pass1
      # xor ax, ax
      # pass1:
      # test cx, cx
      # mov cx, _true
      # jnz pass2
      # xor cx, cx
      # pass2:
      # and ax, cx
      # push ax
      
      bins = 
        [
          0x59, 0x58, 0x85, 0xc0, 0xb8, 0xff, 0xff, 0x75, 0x02, 
          0x31, 0xc0, 0x85, 0xc9, 0xb9, 0xff, 0xff, 0x75, 0x02, 
          0x31, 0xc9, 0x21, 0xc8, 0x50
        ]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_or
      # pop cx
      # pop ax
      # test ax, ax
      # mov ax, _true
      # jnz pass1
      # xor ax, ax
      # pass1:
      # test cx, cx
      # mov cx, _true
      # jnz pass2
      # xor cx, cx
      # pass2:
      # or ax, cx
      # push ax
      
      bins = 
        [
          0x59, 0x58, 0x85, 0xc0, 0xb8, 0xff, 0xff, 0x75, 0x02, 
          0x31, 0xc0, 0x85, 0xc9, 0xb9, 0xff, 0xff, 0x75, 0x02, 
          0x31, 0xc9, 0x09, 0xc8, 0x50
        ]
      bins.map{|x|x.chr}.join
    end
    def cmd_is_xor
      # pop cx
      # pop ax
      # test ax, ax
      # mov ax, _true
      # jnz pass1
      # xor ax, ax
      # pass1:
      # test cx, cx
      # mov cx, _true
      # jnz pass2
      # xor cx, cx
      # pass2:
      # xor ax, cx
      # push ax
      
      bins = 
        [
          0x59, 0x58, 0x85, 0xc0, 0xb8, 0xff, 0xff, 0x75, 0x02, 
          0x31, 0xc0, 0x85, 0xc9, 0xb9, 0xff, 0xff, 0x75, 0x02, 
          0x31, 0xc9, 0x31, 0xc8, 0x50
        ]
      bins.map{|x|x.chr}.join
    end
    def cmd_jit(rel)
      # jump if true
      # pop ax
      # test ax, ax
      # jnz target
      
      bins = [0x58, 0x85, 0xc0, 0x0f, 0x85]
      bins.map{|x|x.chr}.join + as_word(rel)[0..1]
    end
    def cmd_jif(rel)
      # jump if false
      # pop ax
      # test ax, ax
      # jz target
      
      bins = [0x58, 0x85, 0xc0, 0x0f, 0x84]
      bins.map{|x|x.chr}.join + as_word(rel)[0..1]
    end
    def cmd_inc(obj)
      # inc word [obj]
      0xff.chr + 0x06.chr + as_obj(obj)
    end
    def cmd_dec(obj)
      # dec word [obj]
      0xff.chr + 0x0e.chr + as_obj(obj)
    end
    def cmd_iadd
      # 0x20.chr
      raise "Command 'iadd' not implemented."
    end
    def cmd_isub
      # 0x21.chr
      raise "Command 'isub' not implemented."
    end
    def cmd_imul
      # 0x22.chr
      raise "Command 'imul' not implemented."
    end
    def cmd_idiv
      # 0x23.chr
      raise "Command 'idiv' not implemented."
    end
    def cmd_shr(obj)
      # shr word [obj], 1
      0xc1.chr + 0x2e.chr + as_obj(obj) + 0x01.chr
    end
    def cmd_shl(obj)
      # shr word [obj], 1
      0xc1.chr + 0x26.chr + as_obj(obj) + 0x01.chr
    end
    def cmd_rol(obj)
      # rol word [obj], 1
      0xc1.chr + 0x06.chr + as_obj(obj) + 0x01.chr
    end
    def cmd_ror(obj)
      # ror word [obj], 1
      0xc1.chr + 0x0e.chr + as_obj(obj) + 0x01.chr
    end
    def cmd_not
      # pop ax
      # test ax, ax
      # mov ax, _true
      # jz pass
      # xor ax, ax
      # pass:
      # push ax
      
      bins = [0x58, 0x85, 0xc0, 0xb8, 0xff, 0xff, 0x74, 0x02, 0x31, 0xc0, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_and
      # pop cx
      # pop ax
      # and ax, cx
      # push ax
      
      bins = [0x59, 0x58, 0x21, 0xc8, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_or
      # pop cx
      # pop ax
      # or ax, cx
      # push ax
      
      bins = [0x59, 0x58, 0x09, 0xc8, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_xor
      # pop cx
      # pop ax
      # xor ax, cx
      # push ax
      
      bins = [0x59, 0x58, 0x31, 0xc8, 0x50]
      bins.map{|x|x.chr}.join
    end
    def cmd_in
      # 0x2c.chr
      raise "Command 'in' not implemented."
    end
    def cmd_out
      # 0x2d.chr
      raise "Command 'out' not implemented."
    end
  end
end