module Elang
  class MsWinSetupGenerator
    private
    def hex2bin(h)
      Converter.hex2bin(h)
    end
    def build_code_initializer(build_config)
      rv_heap_size = Converter.int2hex(build_config.heap_size, :word, :be)
      first_block_adr = Converter.int2hex(build_config.first_block_offs, :word, :be)
      dynamic_area_adr = Converter.int2hex(build_config.dynamic_area, :word, :be)
      
      if build_config.root_var_count > 0
        cx = Converter.int2hex(build_config.root_var_count, :word, :be)
        di = Converter.int2hex(build_config.variable_offset, :word, :be)
        
        commands = 
          [
            "B9#{cx}",  # mov cx, xx
            "31C0",     # xor ax, ax
            "BF#{di}",  # mov di, variable_offset
            "FC",       # cld
            "F2",       # repnz
            "AB",       # stosw
          ]
        
        init_vars = commands.join
      else
        init_vars = ""
      end
      
      init_cmnd = 
        [
          "8CC8",                     # mov ax, cs
          "050000",                   # add ax, 0
          "8ED0",                     # mov ss, ax
          "8ED8",                     # mov ds, ax
          "8EC0",                     # mov es, ax
          init_vars, 
          "B8#{rv_heap_size}50",      # push heap_size
          "B8#{dynamic_area_adr}50",  # push dynamic_area
          "E80000",                   # call mem_block_init
          "A3#{first_block_adr}"      # mov [first_block], ax
        ]
      
      root_scope = Scope.new
      build_config.symbol_refs << FunctionRef.new(SystemFunction.new("_mem_block_init"), root_scope, 20 + (init_vars.length / 2), :init)
      hex2bin init_cmnd.join
    end
    
    public
    def generate_code_initializer(build_config, sections)
      sections["init"].data = build_code_initializer(build_config)
      ds_offset = ["head", "libs", "subs", "disp", "init", "main"].map{|x|sections[x].size}.sum
      
      if (extra_size = (ds_offset % 16)) > 0
        pad_count = 16 - extra_size
        
        if sections["cons"].size > 0
          sections["main"].data = sections["main"].data + (0.chr * pad_count)
        end
        
        ds_offset = ds_offset + pad_count
      end
      
      sections["init"].data[3, 2] = Converter.int2bin((ds_offset + build_config.code_origin) >> 4, :word)
    end
  end
end
