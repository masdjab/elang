# resources:
# https://wiki.osdev.org/MZ
# https://board.flatassembler.net/topic.php?t=1736
# https://board.flatassembler.net/topic.php?t=15181

module Elang
  class Exe16Formatter < BaseOutputFormatter
    HEADER_SIZE_IN_BYTES = 0x20
    
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
          "8ED8",                     # mov ds, ax
          "8EC0",                     # mov es, ax
          init_vars, 
          "B8#{rv_heap_size}50",      # push heap_size
          "B8#{dynamic_area_adr}50",  # push dynamic_area
          "E80000",                   # call mem_block_init
          "A3#{first_block_adr}"      # mov [first_block], ax
        ]
      
      ref_context = CodeContext.new("init")
      sys_function = build_config.kernel.functions.find{|x|x.name == "_mem_block_init"}
      build_config.symbol_refs << FunctionRef.new(sys_function, ref_context, 18 + (init_vars.length / 2))
      hex2bin init_cmnd.join
    end
    def build_file_header(build_config)
      extra_bytes = 0
      num_of_pages = 0
      relocation_items = 0
      header_size = HEADER_SIZE_IN_BYTES >> 4
      min_alloc_paragraphs = 0x100
      max_alloc_paragraphs = 0xffff
      initial_ss = 0
      initial_sp = 0xfffe
      checksum = 0
      initial_ip = 0
      initial_cs = 0
      relocation_table = 0x1c
      overlay = 0
      overlay_info = ""
      
      init_cmd = 
        [
          "4D5A", 
          Converter.int2hex(extra_bytes, :word, :be), 
          Converter.int2hex(num_of_pages, :word, :be), 
          Converter.int2hex(relocation_items, :word, :be), 
          Converter.int2hex(header_size, :word, :be), 
          Converter.int2hex(min_alloc_paragraphs, :word, :be), 
          Converter.int2hex(max_alloc_paragraphs, :word, :be), 
          Converter.int2hex(initial_ss, :word, :be), 
          Converter.int2hex(initial_sp, :word, :be), 
          Converter.int2hex(checksum, :word, :be), 
          Converter.int2hex(initial_ip, :word, :be), 
          Converter.int2hex(initial_cs, :word, :be), 
          Converter.int2hex(relocation_table, :word, :be), 
          Converter.int2hex(overlay, :word, :be), 
          overlay_info
        ]
      
      hex2bin init_cmd.join
    end
    
    public
    def extension
      "exe"
    end
    def format_output(build_config)
      build_preformat_values build_config
      
      
      build_config.codeset = 
        ["head", "libs", "subs", "disp", "init", "main", "cons"]
        .inject({}){|a,b|a[b]=build_config.codeset[b];a}
      
      
      build_config.codeset["head"] = CodeSection.new("head", :other, Code.align(build_file_header(build_config), 16))
      build_config.codeset["libs"] = CodeSection.new("libs", :code, Code.align(build_config.kernel.code, 16))
      build_config.codeset["cons"] = CodeSection.new("cons", :data, build_config.constant_image)
      build_config.codeset["subs"].data = Code.align(build_config.codeset["subs"].data, 16)
      build_config.codeset["main"].data << Elang::Converter.hex2bin("B8004CCD21")
      
      
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
      
      
      build_config.codeset["init"] = CodeSection.new("init", :code, build_code_initializer(build_config))
      ds_offset = ["libs", "subs", "disp", "init", "main"].map{|x|build_config.codeset[x].data.length}.sum
      
      if (extra_size = (ds_offset % 16)) > 0
        pad_count = 16 - extra_size
        
        if build_config.codeset["cons"].data.length > 0
          build_config.codeset["main"].data << (0.chr * pad_count)
        end
        
        ds_offset = ds_offset + pad_count
      end
      
      build_config.codeset["init"].data[3, 2] = Converter.int2bin((ds_offset) >> 4, :word)
      
      
      resolver = build_config.reference_resolver
      symbol_refs = build_config.symbol_refs
      context_offsets = {}
      
      libs_context = CodeContext.new("libs")
      build_config.kernel.functions.each do |s|
        if s.name == "_send_to_object"
          s.context = build_config.codeset["disp"].context
          s.offset = build_config.method_dispatcher.dispatcher_offset
        else
          s.context = libs_context
        end
      end
      
      
      code_offset = 0
      build_config.codeset.each do |k, v|
        if k != "head"
          context_offsets[v.context.to_s] = code_offset
          code_offset += v.data.length
        end
      end
      
      main_offset = build_config.code_origin + ["head", "libs", "subs", "disp"].map{|x|build_config.codeset[x].data.length}.sum
      image_size = ["libs", "subs", "disp", "init", "main", "cons"].map{|x|build_config.codeset[x].data.length}.sum
      file_size = image_size + build_config.codeset["head"].data.length
      extra_bytes = file_size % 512
      num_of_pages = (file_size >> 9) + (extra_bytes > 0 ? 1 : 0)
      initial_ip = main_offset - HEADER_SIZE_IN_BYTES
      stack_segment = (image_size >> 4) + ((image_size % 16) > 0 ? 1 : 0)
      build_config.codeset["head"].data[2, 2] = Elang::Converter.int2bin(extra_bytes, :word)
      build_config.codeset["head"].data[4, 2] = Elang::Converter.int2bin(num_of_pages, :word)
      build_config.codeset["head"].data[20, 2] = Elang::Converter.int2bin(initial_ip, :word)
      build_config.codeset["head"].data[14, 2] = Elang::Converter.int2bin(stack_segment, :word)
      
      configure_resolver build_config, context_offsets
      
      build_config.codeset.each do |k, v|
        resolver.resolve_references v.context, v.data, symbol_refs, code_offset
      end
      
      build_config.codeset.map{|k,v|v.data}.join
    end
  end
end
