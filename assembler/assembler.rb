require './compiler/tokenizer'
require './utils/converter'

module Assembler
  class Assembler
    def initialize(translator)
      @translator = translator
    end
    def get_int(v)
      if v.is_a?(Integer)
        v
      elsif v.is_a?(String)
        if v[0..1] == '0x'
          v.hex
        else
          v.to_i
        end
      end
    end
    def cmd_nop(*args)
      @translator.cmd_nop
    end
    def cmd_put(*args)
      @translator.cmd_put(get_int(args[0]))
    end
    def cmd_get(*args)
      @translator.cmd_get
    end
    def cmd_store(*args)
      @translator.cmd_store
    end
    def cmd_load(*args)
      @translator.cmd_load(get_int(args[0]))
    end
    def cmd_peek(*args)
      @translator.cmd_peek(get_int(args[0]))
    end
    def cmd_poke(*args)
      @translator.cmd_poke(get_int(args[0]))
    end
    def cmd_read(*args)
      @translator.cmd_read(get_int(args[0]))
    end
    def cmd_write(*args)
      @translator.cmd_write(get_int(args[0]))
    end
    def cmd_enter(*args)
      @translator.cmd_enter(get_int(args[0]))
    end
    def cmd_leave(*args)
      @translator.cmd_leave(get_int(args[0]))
    end
    def cmd_invoke(*args)
      @translator.cmd_invoke
    end
    def cmd_call(*args)
      @translator.cmd_call(get_int(args[0]))
    end
    def cmd_rjmp(*args)
      @translator.cmd_rjmp(get_int(args[0]))
    end
    def cmd_ajmp(*args)
      @translator.cmd_ajmp(get_int(args[0]))
    end
    def cmd_is_null(*args)
      @translator.cmd_is_null
    end
    def cmd_is_eq(*args)
      @translator.cmd_is_eq
    end
    def cmd_is_gt(*args)
      @translator.cmd_is_gt
    end
    def cmd_is_lt(*args)
      @translator.cmd_is_lt
    end
    def cmd_is_ge(*args)
      @translator.cmd_is_ge
    end
    def cmd_is_le(*args)
      @translator.cmd_is_le
    end
    def cmd_is_ne(*args)
      @translator.cmd_is_ne
    end
    def cmd_is_not(*args)
      @translator.cmd_is_not
    end
    def cmd_is_and(*args)
      @translator.cmd_is_and
    end
    def cmd_is_or(*args)
      @translator.cmd_is_or
    end
    def cmd_is_xor(*args)
      @translator.cmd_is_xor
    end
    def cmd_jit(*args)
      @translator.cmd_jit(get_int(args[0]))
    end
    def cmd_jif(*args)
puts "cmd_jif => args: #{args.inspect}"
      @translator.cmd_jif(get_int(args[0]))
    end
    def cmd_inc(*args)
      @translator.cmd_inc(get_int(args[0]))
    end
    def cmd_dec(*args)
      @translator.cmd_dec(get_int(args[0]))
    end
    def cmd_iadd(*args)
      @translator.cmd_iadd
    end
    def cmd_isub(*args)
      @translator.cmd_isub
    end
    def cmd_imul(*args)
      @translator.cmd_imul
    end
    def cmd_idiv(*args)
      @translator.cmd_idiv
    end
    def cmd_shr(*args)
      @translator.cmd_shr(get_int(args[0]))
    end
    def cmd_shl(*args)
      @translator.cmd_shl(get_int(args[0]))
    end
    def cmd_rol(*args)
      @translator.cmd_rol(get_int(args[0]))
    end
    def cmd_ror(*args)
      @translator.cmd_ror(get_int(args[0]))
    end
    def cmd_not(*args)
      @translator.cmd_not
    end
    def cmd_and(*args)
      @translator.cmd_and
    end
    def cmd_or(*args)
      @translator.cmd_or
    end
    def cmd_xor(*args)
      @translator.cmd_xor
    end
    def cmd_in(*args)
      @translator.cmd_in
    end
    def cmd_out(*args)
      @translator.cmd_out
    end
    def extract_commands(tokens)
      commands = []
      end_inst = true
      
      tokens.each do |tok|
        if ![:cr, :lf, :crlf].include?(tok.type)
          if end_inst
            commands << {cmd: nil, args: []}
            end_inst = false
          end
          
          if commands.last[:cmd].nil?
            commands.last[:cmd] = tok.text
          else
            commands.last[:args] << tok.text
          end
        else
          end_inst = true
        end
      end
      
      commands
    end
    def parse(code)
      translated = []
      
      tokenizer = Elang::Tokenizer.new
      tokens = tokenizer.parse(code)
      commands = extract_commands(tokens)
      
      commands.each do |cmd|
        if respond_to?(instr = :"cmd_#{cmd[:cmd]}")
          mnemonic = __send__(instr, *cmd[:args])
          translated << mnemonic if !mnemonic.empty?
        else
          raise "Invalid command: #{cmd[:cmd]}(#{cmd[:args].join(", ")})"
        end
      end
      
      translated
    end
  end
end
