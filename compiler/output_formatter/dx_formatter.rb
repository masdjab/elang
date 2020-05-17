module Elang
  class DxFormatter < BaseOutputFormatter
    private
    def configure_dispatcher(build_config)
      build_config.method_dispatcher.classes = build_config.classes
      build_config.method_dispatcher.code_origin = build_config.code_origin
    end
    def configure_resolver(build_config, context_offsets)
      build_config.reference_resolver.function_names = build_config.function_names
      build_config.reference_resolver.classes = build_config.classes
      build_config.reference_resolver.string_constants = build_config.string_constants
      build_config.reference_resolver.variable_offset = build_config.variable_offset
      build_config.reference_resolver.code_origin = build_config.code_origin
      build_config.reference_resolver.context_offsets = context_offsets
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
      
      ref_context = CodeContext.new("init")
      sys_function = build_config.kernel.functions.find{|x|x.name == "_mem_block_init"}
      build_config.symbol_refs << FunctionRef.new(sys_function, ref_context, 14 + (init_vars.length / 2))
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
      
      
      build_config.codeset = 
        ["head", "libs", "subs", "disp", "init", "main", "cons"]
        .inject({}){|a,b|a[b]=build_config.codeset[b];a}
      
      
      build_config.codeset["head"] = CodeSection.new("head", :other, Code.align(hex2bin("B80000000050C3"), 16))
      build_config.codeset["libs"] = CodeSection.new("libs", :code, Code.align(build_config.kernel.code, 16))
      build_config.codeset["init"] = CodeSection.new("init", :code, build_code_initializer(build_config))
      build_config.codeset["cons"] = CodeSection.new("cons", :data, build_config.constant_image)
      build_config.codeset["subs"].data = Code.align(build_config.codeset["subs"].data, 16)
      build_config.codeset["main"].data << hex2bin("E800000000")
      
      
      main_context = build_config.codeset["main"].context
      sys_function = build_config.kernel.functions.find{|x|x.name == "exit_process"}
      symbol_ref = FunctionRef.new(sys_function, main_context, build_config.codeset.length - 8)
      build_config.symbol_refs << symbol_ref
      
      
      configure_dispatcher build_config
      build_config.codeset["disp"] = CodeSection.new("disp", :code, "")
      build_config.codeset["disp"].data = 
        Code.align(
          build_config.method_dispatcher.build_obj_method_dispatcher(
            build_config.symbols, 
            build_config.symbol_refs, 
            build_config.codeset["disp"]
          ), 
          16
        )
      
      
      main_offset = build_config.code_origin + ["head", "libs", "subs", "disp"].map{|x|build_config.codeset[x].data.length}.sum
      build_config.codeset["head"].data[1, 4] = Elang::Converter.int2bin(main_offset, :dword)
      
      
      ds_offset = ["head", "libs", "subs", "disp", "init", "main"].map{|x|build_config.codeset[x].data.length}.sum
      
      if (extra_size = (ds_offset % 16)) > 0
        pad_count = 16 - extra_size
        
        if build_config.codeset["cons"].data.length > 0
          build_config.codeset["main"].data << (0.chr * pad_count)
        end
        
        ds_offset = ds_offset + pad_count
      end
      
      
      resolver = build_config.reference_resolver
      symbol_refs = build_config.symbol_refs
      context_offsets = {}
      code_offset = 0
      
      libs_context = CodeContext.new("libs")
      build_config.kernel.functions.each do |s|
        if s.name == "_send_to_object"
          s.context = build_config.codeset["disp"].context
          s.offset = build_config.method_dispatcher.dispatcher_offset
        else
          s.context = libs_context
        end
      end
      
      
      build_config.codeset.each do |k, v|
        context_offsets[v.context.to_s] = code_offset
        code_offset += v.data.length
      end
      
      data_offset = build_config.code_origin + context_offsets["cons"]
      build_config.string_constants.each{|k, v|v[:offset] += data_offset}
      
      configure_resolver build_config, context_offsets
      
      build_config.codeset.each do |k, v|
        resolver.resolve_references v.context, v.data, symbol_refs, code_offset
      end
      
      build_config.codeset.map{|k,v|v.data}.join
    end
  end
end
