module Elang
  class PeFormatter < BaseOutputFormatter
    HEADER_SIZE_IN_BYTES = 0x20
    
    private
    def configure_dispatcher(build_config)
      build_config.method_dispatcher.classes = build_config.classes
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
    
    public
    def extension
      "exe"
    end
    def format_output(build_config)
      build_preformat_values build_config
      
      
      import_section_builder = ImportSectionBuilder.new(build_config.symbols)
      import_section_builder.image_base = 0x2000
      import_section_builder.build
      
      mz_header = MzHeader.new
      mz_header.extra_bytes = 0
      mz_header.num_of_pages = 0
      mz_header.relocation_items = 0
      mz_header.header_size = HEADER_SIZE_IN_BYTES >> 4
      mz_header.min_alloc_paragraphs = 0x10
      mz_header.max_alloc_paragraphs = 0xffff
      mz_header.initial_ss = 0
      mz_header.initial_sp = 0xfffe
      mz_header.checksum = 0
      mz_header.initial_ip = 0
      mz_header.initial_cs = 0
      mz_header.relocation_table = 0x1c
      mz_header.overlay = 0
      mz_header.overlay_info = ""
      
      code_section = PeSection.new
      itbl_section = PeSection.new
      
      pe_header = PeHeader.new
      pe_header.mz_header = mz_header
      pe_header.msdos_stub = MsdosStub.new(0x1c)
      pe_header.signature = "PE" + 0.chr + 0.chr
      pe_header.machine = PeHeader::MACHINE_TYPE_I386
      pe_header.number_of_sections = 2
      pe_header.timestamp = Time.new
      pe_header.pointer_to_symbol_table = 0
      pe_header.number_of_symbols = 0
      pe_header.size_of_optional_header = 0xe0
      pe_header.characteristics = PeHeader::CHARACTERISTICS_DEFAULT
      pe_header.magic_number = PeHeader::MAGIC_NUMBER_PE32
      pe_header.linker_version = PeVersion.new(1, 0)
      pe_header.size_of_code = 0x200
      pe_header.size_of_initialized_data = 0x200
      pe_header.size_of_uninitialized_data = 0
      pe_header.entry_point = 0x1000
      pe_header.base_of_code = 0x1000
      pe_header.base_of_data = 0x2000
      pe_header.image_base = 0x400000
      pe_header.section_alignment = 0x1000
      pe_header.file_alignment = 0x100
      pe_header.os_version = PeVersion.new(1, 0)
      pe_header.image_version = PeVersion.new(0, 0)
      pe_header.subsystem_version = PeVersion.new(4, 0)
      pe_header.win32_version_value = 0
      pe_header.size_of_image = 0x3000
      pe_header.size_of_headers = 0x200
      pe_header.checksum = 0
      pe_header.subsystem = PeHeader::SUBSYSTEM_GUI
      pe_header.dll_characteristics = 0
      pe_header.size_of_stack_reserve = 0x1000
      pe_header.size_of_stack_commit = 0x1000
      pe_header.size_of_heap_reserve = 0x10000
      pe_header.size_of_heap_commit = 0
      pe_header.loader_flags = 0
      pe_header.list_of_rvas = PeHeader.create_rvas_template
      pe_header.sections = [code_section, itbl_section]
      
      
      build_config.codeset["head"] = CodeSection.new("head", :other, Code.align(pe_header.to_bin, 0x200))
      build_config.codeset["libs"] = CodeSection.new("libs", :code, Code.align(build_config.kernel.code, 16))
      build_config.codeset["cons"] = CodeSection.new("cons", :data, build_config.constant_image)
      build_config.codeset["subs"].data = Code.align(build_config.codeset["subs"].data, 16)
      build_config.codeset["main"].data << Elang::Converter.hex2bin("FF1580200000")
      build_config.codeset["itbl"] = CodeSection.new("itbl", :data, Code.align(import_section_builder.image, pe_header.file_alignment))
      
      
      build_config.codeset = 
        ["head", "libs", "subs", "disp", "init", "main", "cons", "itbl"]
        .inject({}){|a,b|a[b]=build_config.codeset[b];a}
      
      
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
      code_size = ["libs", "subs", "disp", "init", "main"].map{|x|build_config.codeset[x].data.length}.sum
      
      if (pad_count = Code.pad_size(code_size, 16)) > 0
        if build_config.codeset["cons"].data.length > 0
          build_config.codeset["main"].data << (0.chr * pad_count)
        end
        
        code_size += pad_count
      end
      
      cons_size = build_config.codeset["cons"].data.length
      pad_count = Code.pad_size(code_size + cons_size, pe_header.file_alignment)
      build_config.codeset["cons"].data << 0.chr * pad_count
      
      build_config.codeset["init"].data[3, 2] = Converter.int2bin((code_size) >> 4, :word)
      
      
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
      mz_header.extra_bytes = extra_bytes = file_size % 512
      mz_header.num_of_pages = (file_size >> 9) + (extra_bytes > 0 ? 1 : 0)
      mz_header.initial_ip = main_offset - HEADER_SIZE_IN_BYTES
      mz_header.initial_ss = (image_size >> 4) + ((image_size % 16) > 0 ? 1 : 0)
      
      raw_pe_header_size = 0x80 + 0x18 + pe_header.size_of_optional_header + pe_header.sections.count * 0x28
      actual_pe_header_size = Code.size_align(raw_pe_header_size, pe_header.file_alignment)
      
      code_section.name = ".text"
      code_section.virtual_size = image_size
      code_section.virtual_address = 0x1000
      code_section.size_of_raw_data = Code.size_align(image_size, pe_header.file_alignment)
      code_section.pointer_to_raw_data = actual_pe_header_size
      code_section.pointer_to_relocations = 0
      code_section.pointer_to_line_numbers = 0
      code_section.number_of_relocations = 0
      code_section.number_of_line_numbers = 0
      code_section.section_flag = PeSection::SECTION_CODE | PeSection::SECTION_MEMORY_EXECUTE | PeSection::SECTION_MEMORY_READABLE
      
      itbl_section.name = ".idata"
      itbl_section.virtual_size = import_section_builder.image.length
      itbl_section.virtual_address = 0x2000
      itbl_section.size_of_raw_data = build_config.codeset["itbl"].data.length
      itbl_section.pointer_to_raw_data = code_section.pointer_to_raw_data + code_section.size_of_raw_data
      itbl_section.pointer_to_relocations = 0
      itbl_section.pointer_to_line_numbers = 0
      itbl_section.number_of_relocations = 0
      itbl_section.number_of_line_numbers = 0
      itbl_section.section_flag = PeSection::SECTION_INITIALIZED_DATA | PeSection::SECTION_MEMORY_READABLE | PeSection::SECTION_MEMORY_WRITABLE
      
      build_config.codeset["head"].data = Code.align(pe_header.to_bin, 16)
      
      
      configure_resolver build_config, context_offsets
      
      build_config.codeset.each do |k, v|
        resolver.resolve_references v.context, v.data, symbol_refs, code_offset
      end
      
      build_config.codeset.map{|k,v|v.data}.join
    end
  end
end
