# require 'converter'

module Assembler
  class BaseTranslator
    private
    def as_byte(v)
      Elang::Utils::Converter.int_to_byte(v)
    end
    def as_word(v)
      Elang::Utils::Converter.int_to_word(v)
    end
    def as_dword(v)
      Elang::Utils::Converter.int_to_dword(v)
    end
    def as_obj(v)
      as_dword(v)
    end
    def as_adr(v)
      as_dword(v)
    end
    def as_index(v)
      as_byte(v)
    end
    
    public
    def cmd_nop
      0x01.chr
    end
    def cmd_put(obj)
      0x02.chr + as_obj(obj)
    end
    def cmd_get
      0x03.chr
    end
    def cmd_store(obj)
      0x04.chr
    end
    def cmd_load(adr)
      0x05.chr + as_adr(adr)
    end
    def cmd_peek(index)
      0x06.chr + as_index(index)
    end
    def cmd_poke(index)
      0x07.chr + as_index(index)
    end
    def cmd_read(ss)
      0x08.chr + as_byte(ss)
    end
    def cmd_write(ss)
      0x09.chr + as_byte(ss)
    end
    def cmd_enter(nn)
      0x0a.chr + as_byte(nn)
    end
    def cmd_leave(nn)
      0x0b.chr + as_byte(nn)
    end
    def cmd_invoke
      0x0c.chr
    end
    def cmd_call(rel)
      0x0d.chr + as_dword(rel)
    end
    def cmd_rjmp(rel)
      0x0e.chr + as_dword(rel)
    end
    def cmd_ajmp(adr)
      0x0f.chr + as_adr(adr)
    end
    def cmd_is_null
      0x10.chr
    end
    def cmd_is_eq
      0x11.chr
    end
    def cmd_is_gt
      0x12.chr
    end
    def cmd_is_lt
      0x13.chr
    end
    def cmd_is_ge
      0x14.chr
    end
    def cmd_is_le
      0x15.chr
    end
    def cmd_is_ne
      0x16.chr
    end
    def cmd_is_not
      0x17.chr
    end
    def cmd_is_and
      0x18.chr
    end
    def cmd_is_or
      0x19.chr
    end
    def cmd_is_xor
      0x1a.chr
    end
    def cmd_jit(rel)
      0x1b.chr + as_dword(rel)
    end
    def cmd_jif(rel)
      0x1c.chr + as_dword(rel)
    end
    def cmd_inc(obj)
      0x1e.chr + as_obj(obj)
    end
    def cmd_dec(obj)
      0x1f.chr + as_obj(obj)
    end
    def cmd_iadd
      0x20.chr
    end
    def cmd_isub
      0x21.chr
    end
    def cmd_imul
      0x22.chr
    end
    def cmd_idiv
      0x23.chr
    end
    def cmd_shr(obj)
      0x24.chr + as_obj(obj)
    end
    def cmd_shl(obj)
      0x25.chr + as_obj(obj)
    end
    def cmd_rol(obj)
      0x26.chr + as_obj(obj)
    end
    def cmd_ror(obj)
      0x27.chr + as_obj(obj)
    end
    def cmd_not
      0x28.chr
    end
    def cmd_and
      0x29.chr
    end
    def cmd_or
      0x2a.chr
    end
    def cmd_xor
      0x2b.chr
    end
    def cmd_in
      0x2c.chr
    end
    def cmd_out
      0x2d.chr
    end
  end
end
