module Elang
  class DxFormatter < BaseOutputFormatter
    private
    def configure_dispatcher(build_config)
      build_config.method_dispatcher.classes = build_config.classes
      build_config.method_dispatcher.code_origin = build_config.code_origin
    end
    def configure_resolver(build_config, dispatcher_offset)
      build_config.reference_resolver.function_names = build_config.function_names
      build_config.reference_resolver.classes = build_config.classes
      build_config.reference_resolver.string_constants = build_config.string_constants
      build_config.reference_resolver.variable_offset = build_config.variable_offset
      build_config.reference_resolver.dispatcher_offset = dispatcher_offset
    end
    def build_code_initializer(build_config)
      rv_heap_size = Converter.int2hex(build_config.heap_size, :dword, :be)
      first_block_adr = Converter.int2hex(build_config.first_block_offs, :dword, :be)
      dynamic_area_adr = Converter.int2hex(build_config.dynamic_area, :dword, :be)
      
      if build_config.root_var_count > 0
        cx = Converter.int2hex(build_config.root_var_count, :dword, :be)
        di = Converter.int2hex(build_config.variable_offset, :dword, :be)
        
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
          init_vars, 
          "B8#{rv_heap_size}50",      # push heap_size
          "B8#{dynamic_area_adr}50",  # push dynamic_area
          "E800000000",               # call mem_block_init
          "A3#{first_block_adr}"      # mov [first_block], ax
        ]
      
      root_scope = Scope.new
      build_config.symbol_refs << FunctionRef.new(SystemFunction.new("_mem_block_init"), root_scope, 14 + (init_vars.length / 2), "init")
      hex2bin init_cmnd.join
    end
    def calc_sections_size(sections, section_names)
      section_names.map{|x|sections[x].data.length}.sum
    end
    
    public
    def extension
      "dx"
    end
    def format_output(build_config)
      build_preformat_values build_config
      
      build_config.codeset["head"] = CodeSection.new("head", :other, Code.align(hex2bin("B80000000050C3"), 16))
      build_config.codeset["libs"] = CodeSection.new("libs", :code, Code.align(build_config.kernel.code, 16))
      build_config.codeset["init"] = CodeSection.new("init", :code, build_code_initializer(build_config))
      build_config.codeset["cons"] = CodeSection.new("data", :data, build_config.constant_image)
      
      build_config.codeset["subs"].data = Code.align(build_config.codeset["subs"].data, 16)
      
      build_config.codeset["main"].data << hex2bin("E800000000")
      symbol_ref = 
        FunctionRef.new \
          SystemFunction.new("exit_process"), 
          Scope.new, 
          build_config.codeset.length - 8, 
          "main"
      build_config.symbol_refs << symbol_ref
      
      
      head_size = build_config.codeset["head"].data.length
      libs_size = build_config.codeset["libs"].data.length
      subs_size = build_config.codeset["subs"].data.length
      init_size = build_config.codeset["init"].data.length
      cons_size = build_config.codeset["cons"].data.length
      
#puts
#puts "classes:"
#puts build_config.classes.inspect
      configure_dispatcher build_config
      asm = build_config.method_dispatcher.build_obj_method_dispatcher(head_size + libs_size, subs_size)
      build_config.codeset["disp"] = CodeSection.new("disp", :code, Code.align(asm.code, 16))
      disp_size = build_config.codeset["disp"].data.length
      mapper_method = asm.instructions.map{|x|x.to_s}.join("\r\n")
#puts
#puts "*** OBJECT METHOD MAPPER ***"
#puts mapper_method
#puts
      
      build_config.codeset = 
        ["head", "libs", "subs", "disp", "init", "main", "cons"]
        .inject({}){|a,b|a[b]=build_config.codeset[b];a}
      
      
      main_offset = build_config.code_origin + head_size + libs_size + subs_size + disp_size
      build_config.codeset["head"].data[1, 4] = Elang::Converter.int2bin(main_offset, :dword)
      
      
      if cons_size > 0
        x_size = calc_sections_size(build_config.codeset, ["init", "main"])
        
        if (extra_size = (x_size % 16)) > 0
          pad_count = 16 - extra_size
          build_config.codeset["main"].data << (0.chr * pad_count)
        end
      end
      
      if head_size > 0
        build_config.kernel.functions.each{|k,v|v[:offset] += head_size}
      end
      
      if (sx = head_size + libs_size) > 0
        build_config.symbols.items.each do |s|
          if s.is_a?(Function)
            s.offset = s.offset + sx
          end
        end
      end
      
      configure_resolver build_config, build_config.method_dispatcher.dispatcher_offset
      build_config.reference_resolver.resolve_references "subs", build_config.codeset["subs"].data, build_config.symbol_refs, head_size + libs_size
      build_config.reference_resolver.resolve_references "init", build_config.codeset["init"].data, build_config.symbol_refs, head_size + libs_size + subs_size + disp_size
      build_config.reference_resolver.resolve_references "main", build_config.codeset["main"].data, build_config.symbol_refs, head_size + libs_size + subs_size + disp_size + init_size
      
      build_config.codeset.map{|k,v|v.data}.join
    end
  end
end
