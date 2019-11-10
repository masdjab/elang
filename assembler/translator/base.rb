# require 'converter'

module Assembler
  class BaseTranslator
    private
    def bhex(v)
      Elang::Utils::Converter.int_to_byte(v).bytes
    end
    def whex(v)
      Elang::Utils::Converter.int_to_word(v).bytes
    end
    def as_obj(v)
      whex(v)
    end
    def as_adr(v)
      whex(v)
    end
    def as_index(v)
      bhex(v)
    end
    
    public
    def cmd_nop
      [0x01]
    end
    def cmd_put(obj)
      [0x02] + as_obj(obj)
    end
    def cmd_get
      [0x03]
    end
    def cmd_store(obj)
      [0x04]
    end
    def cmd_load(adr)
      [0x05] + as_adr(adr)
    end
    def cmd_peek(index)
      [0x06] + as_index(index)
    end
    def cmd_poke(index)
      [0x07] + as_index(index)
    end
    def cmd_read(ss)
      [0x08] + bhex(ss)
    end
    def cmd_write(ss)
      [0x09] + bhex(ss)
    end
    def cmd_enter(nn)
      [0x0a] + bhex(nn)
    end
    def cmd_leave(nn)
      [0x0b] + bhex(nn)
    end
    def cmd_invoke
      [0x0c]
    end
    def cmd_call(rel)
      [0x0d] + whex(rel)
    end
    def cmd_rjmp(rel)
      [0x0e] + whex(rel)
    end
    def cmd_ajmp(adr)
      [0x0f] + as_adr(adr)
    end
    def cmd_is_null
      [0x10]
    end
    def cmd_is_eq
      [0x11]
    end
    def cmd_is_gt
      [0x12]
    end
    def cmd_is_lt
      [0x13]
    end
    def cmd_is_ge
      [0x14]
    end
    def cmd_is_le
      [0x15]
    end
    def cmd_is_ne
      [0x16]
    end
    def cmd_is_not
      [0x17]
    end
    def cmd_is_and
      [0x18]
    end
    def cmd_is_or
      [0x19]
    end
    def cmd_is_xor
      [0x1a]
    end
    def cmd_if_true
      [0x1b]
    end
    def cmd_if_false
      [0x1c]
    end
    def cmd_end_if
      [0x1d]
    end
    def cmd_inc(obj)
      [0x1e] + as_obj(obj)
    end
    def cmd_dec(obj)
      [0x1f] + as_obj(obj)
    end
    def cmd_iadd
      [0x20]
    end
    def cmd_isub
      [0x21]
    end
    def cmd_imul
      [0x22]
    end
    def cmd_idiv
      [0x23]
    end
    def cmd_shr(obj)
      [0x24] + as_obj(obj)
    end
    def cmd_shl(obj)
      [0x25] + as_obj(obj)
    end
    def cmd_rol(obj)
      [0x26] + as_obj(obj)
    end
    def cmd_ror(obj)
      [0x27] + as_obj(obj)
    end
    def cmd_not
      [0x28]
    end
    def cmd_and
      [0x29]
    end
    def cmd_or
      [0x2a]
    end
    def cmd_xor
      [0x2b]
    end
    def cmd_in
      [0x2c]
    end
    def cmd_out
      [0x2d]
    end
  end
end
