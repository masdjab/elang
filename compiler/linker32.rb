module Elang
  class Linker32
    private
    def hex2bin(h)
      Converter.hex2bin(h)
    end
    def build_root_var_indices(build_config)
      root_var_count = 0
      
      build_config.symbols.items.each do |s|
        if s.is_a?(Variable) && s.scope.root?
          root_var_count += 1
          s.index = root_var_count
        end
      end
      
      build_config.root_var_count = root_var_count
    end
    def build_reserved_image(build_config)
      build_config.reserved_image = 0.chr * (4 * build_config.reserved_var_count)
    end
    def build_string_constants(build_config)
      cons = {}
      offs = build_config.reserved_image.length
      
      build_config.symbols.items.each do |s|
        if s.is_a?(Constant)
          text = s.value
          text = text.gsub("\\r", "\r")
          text = text.gsub("\\n", "\n")
          text = text.gsub("\\t", "\t")
          text = text.gsub("\\\"", "\"")
          
          lgth = text.length
          cons[s.name] = {text: text, length: lgth, offset: offs}
          offs = offs + lgth + 4
        end
      end
      
      build_config.string_constants = cons
    end
    def build_constant_data(build_config)
      cons = ""
      
      build_config.string_constants.each do |k,v|
        lgth = Converter.int2bin(v[:length], :word)
        cons << "#{lgth}#{v[:text]}"
      end
      
      if (cons.length > 0) && ((cons.length % 4) > 0)
        cons << (0.chr * (4 - (cons.length % 4)))
      end
      
      cons = !cons.empty? ? build_config.reserved_image + cons : ""
      
      build_config.constant_image = cons
    end
    def calc_variable_offset(build_config)
      build_config.variable_offset = (build_config.reserved_image + build_config.constant_image).length
    end
    def calc_dynamic_area(build_config)
      build_config.dynamic_area = build_config.variable_offset + (build_config.root_var_count * 4)
    end
    def build_class_hierarchy(build_config)
      build_config.function_names = build_config.symbols.get_function_names
      build_config.classes = build_config.symbols.get_classes_hierarchy
    end
    def build_code_initializer(build_config)
      #rv_heap_size = Converter.int2hex(build_config.heap_size, :dword, :be)
      #first_block_adr = Converter.int2hex(build_config.first_block_offs, :dword, :be)
      #dynamic_area_adr = Converter.int2hex(build_config.dynamic_area, :dword, :be)
      
      #if build_config.root_var_count > 0
      #  cx = Converter.int2hex(build_config.root_var_count, :dword, :be)
      #  di = Converter.int2hex(build_config.variable_offset, :dword, :be)
        
      #  commands = 
      #    [
      #      "B9#{cx}",  # mov cx, xx
      #      "31C0",     # xor ax, ax
      #      "BF#{di}",  # mov di, variable_offset
      #      "FC",       # cld
      #      "F2",       # repnz
      #      "AB",       # stosw
      #    ]
        
      #  init_vars = commands.join
      #else
      #  init_vars = ""
      #end
      
      #init_cmnd = 
      #  [
      #    "8CC8",                     # mov ax, cs
      #    "050000",                   # add ax, 0
      #    "8ED0",                     # mov ss, ax
      #    "8ED8",                     # mov ds, ax
      #    "8EC0",                     # mov es, ax
      #    init_vars, 
      #    "B8#{rv_heap_size}50",      # push heap_size
      #    "B8#{dynamic_area_adr}50",  # push dynamic_area
      #    "E80000",                   # call mem_block_init
      #    "A3#{first_block_adr}"      # mov [first_block], ax
      #  ]
      
      #root_scope = Scope.new
      #build_config.symbol_refs << FunctionRef.new(SystemFunction.new("_mem_block_init"), root_scope, 20 + (init_vars.length / 2), :init)
      #hex2bin init_cmnd.join
      
      ""
    end
    def create_build_config(kernel, language, symbols, symbol_refs, codeset)
      build_config = BuildConfig.new
      build_config.kernel = kernel
      build_config.language = language
      build_config.symbols = symbols
      build_config.symbol_refs = symbol_refs
      build_config.codeset = codeset
      build_config.code_origin = 0
      build_config.heap_size = 0x8000
      build_config.first_block_offs = 0
      build_config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      build_root_var_indices build_config
      build_reserved_image build_config
      build_string_constants build_config
      build_constant_data build_config
      calc_variable_offset build_config
      calc_dynamic_area build_config
      build_class_hierarchy build_config
      build_config
    end
    def create_dispatcher(build_config)
      dispatcher = MethodDispatcher16.new
      dispatcher.classes = build_config.classes
      dispatcher.code_origin = build_config.code_origin
      dispatcher
    end
    def create_resolver(build_config, dispatcher_offset)
      resolver = ReferenceResolver16.new(build_config.kernel, build_config.language)
      resolver.function_names = build_config.function_names
      resolver.classes = build_config.classes
      resolver.string_constants = build_config.string_constants
      resolver.variable_offset = build_config.variable_offset
      resolver.dispatcher_offset = dispatcher_offset
      resolver
    end
    
    public
    def link(kernel, language, symbols, symbol_refs, codeset)
      build_config = create_build_config(kernel, language, symbols, symbol_refs, codeset)
      
      head_code = Code.align(hex2bin("B80000000050C3"), 16)
      libs_code = build_config.kernel.code
      subs_code = Code.align(codeset.render(:subs), 16)
      main_code = codeset.render(:main)
      head_size = head_code.length
      libs_size = libs_code.length
      subs_size = subs_code.length
      main_size = main_code.length
      cons_size = build_config.constant_image.length
      
      
#puts
#puts "classes:"
#puts build_config.classes.inspect
      dispatcher = create_dispatcher(build_config)
      asm = dispatcher.build_obj_method_dispatcher(head_size + libs_size, subs_size)
      dispatcher_code = Code.align(asm.code, 16)
      dispatcher_size = dispatcher_code.length
      mapper_method = asm.instructions.map{|x|x.to_s}.join("\r\n")
      dispatcher_offset = dispatcher.dispatcher_offset
#puts
#puts "*** OBJECT METHOD MAPPER ***"
#puts mapper_method
#puts
      
      
      init_code = build_code_initializer(build_config)
      init_size = init_code.length
      ds_offset = head_size + libs_size + subs_size + dispatcher_size + init_size + main_size
      
      if (extra_size = (ds_offset % 16)) > 0
        pad_count = 16 - extra_size
        
        if cons_size > 0
          main_code = main_code + (0.chr * pad_count)
          main_size = main_size + pad_count
        end
        
        ds_offset = ds_offset + pad_count
      end
      
      #init_code[3, 2] = Converter.int2bin((ds_offset + build_config.code_origin) >> 4, :word)
      
      
      main_offset = build_config.code_origin + head_size + libs_size + subs_size + dispatcher_size
      head_code[1, 4] = Elang::Converter.int2bin(main_offset, :dword)
      
      if libs_size > 0
        build_config.kernel.functions.each do |k,v|
          v[:offset] += head_size
        end
      end
      
      symbols.items.each do |s|
        if s.is_a?(Function)
          s.offset = s.offset + head_size + libs_size
        end
      end
      
      resolver = create_resolver(build_config, dispatcher_offset)
      resolver.resolve_references :subs, subs_code, symbol_refs, head_size + libs_size
      resolver.resolve_references :init, init_code, symbol_refs, head_size + libs_size + subs_size + dispatcher_size
      resolver.resolve_references :main, main_code, symbol_refs, head_size + libs_size + subs_size + dispatcher_size + init_size
      
      head_code + libs_code + subs_code + dispatcher_code + init_code + main_code + build_config.constant_image
    end
  end
end
