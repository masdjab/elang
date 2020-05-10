module Elang
  class ComFormatter < BaseOutputFormatter
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
      build_config.symbol_refs << FunctionRef.new(SystemFunction.new("_mem_block_init"), root_scope, 20 + (init_vars.length / 2), "init")
      hex2bin init_cmnd.join
    end
    
    public
    def extension
      "com"
    end
    def format_output(build_config)
      build_preformat_values build_config
      
      build_config.codeset["head"] = CodeSection.new("head", :other, Code.align(hex2bin("B8000050C3"), 16))
      build_config.codeset["libs"] = CodeSection.new("libs", :code, build_config.kernel.code)
      build_config.codeset["cons"] = CodeSection.new("data", :data, build_config.constant_image)
      build_config.codeset["subs"].data = Code.align(build_config.codeset["subs"].data, 16)
      build_config.codeset["main"].data << Elang::Converter.hex2bin("CD20")
      
#puts
#puts "classes:"
#puts build_config.classes.inspect
      configure_dispatcher build_config
      asm = build_config.method_dispatcher.build_obj_method_dispatcher(build_config.codeset["head"].data.length + build_config.codeset["libs"].data.length, build_config.codeset["subs"].data.length)
      build_config.codeset["disp"] = CodeSection.new("disp", :code, Code.align(asm.code, 16))
      mapper_method = asm.instructions.map{|x|x.to_s}.join("\r\n")
#puts
#puts "*** OBJECT METHOD MAPPER ***"
#puts mapper_method
#puts
      
      build_config.codeset = 
        ["head", "libs", "subs", "disp", "init", "main", "cons"]
        .inject({}){|a,b|a[b]=build_config.codeset[b];a}
      
      
      main_offset = build_config.code_origin + ["head", "libs", "subs", "disp"].map{|x|build_config.codeset[x].data.length}.sum
      build_config.codeset["head"].data[1, 2] = Elang::Converter.int2bin(main_offset, :word)
      
      
      build_config.codeset["init"] = CodeSection.new("init", :code, build_code_initializer(build_config))
      ds_offset = ["head", "libs", "subs", "disp", "init", "main"].map{|x|build_config.codeset[x].data.length}.sum
      
      if (extra_size = (ds_offset % 16)) > 0
        pad_count = 16 - extra_size
        
        if build_config.codeset["cons"].data.length > 0
          build_config.codeset["main"].data << (0.chr * pad_count)
        end
        
        ds_offset = ds_offset + pad_count
      end
      
      build_config.codeset["init"].data[3, 2] = Converter.int2bin((ds_offset + build_config.code_origin) >> 4, :word)
      
      
      if build_config.codeset["libs"].data.length > 0
        build_config.kernel.functions.each do |k,v|
          v[:offset] += build_config.codeset["head"].data.length
        end
      end
      
      build_config.symbols.items.each do |s|
        if s.is_a?(Function)
          s.offset = s.offset + build_config.codeset["head"].data.length + build_config.codeset["libs"].data.length
        end
      end
      
      configure_resolver build_config, build_config.method_dispatcher.dispatcher_offset
      build_config.reference_resolver.resolve_references "subs", build_config.codeset["subs"].data, build_config.symbol_refs, build_config.codeset["head"].data.length + build_config.codeset["libs"].data.length
      build_config.reference_resolver.resolve_references "init", build_config.codeset["init"].data, build_config.symbol_refs, build_config.codeset["head"].data.length + build_config.codeset["libs"].data.length + build_config.codeset["subs"].data.length + build_config.codeset["disp"].data.length
      build_config.reference_resolver.resolve_references "main", build_config.codeset["main"].data, build_config.symbol_refs, build_config.codeset["head"].data.length + build_config.codeset["libs"].data.length + build_config.codeset["subs"].data.length + build_config.codeset["disp"].data.length + build_config.codeset["init"].data.length
      
      build_config.codeset.map{|k,v|v.data}.join
    end
  end
end
