module Elang
  class Linker
    private
    def initialize(linker_options)
      @linker_options = linker_options
      @extra_byte_size = @linker_options.var_byte_size > 2 ? @linker_options.var_byte_size - 2 : 0
      @dispatcher = @linker_options.method_dispatcher
      @resolver = @linker_options.reference_resolver
    end
    def imm2hex(value)
      Converter.int2hex(value, @linker_options.var_code_size, :be)
    end
    def hex2bin(h)
      Converter.hex2bin(h)
    end
    def configure_dispatcher(build_config)
      @dispatcher.classes = build_config.classes
      @dispatcher.code_origin = build_config.code_origin
    end
    def configure_resolver(build_config, dispatcher_offset)
      @resolver.function_names = build_config.function_names
      @resolver.classes = build_config.classes
      @resolver.string_constants = build_config.string_constants
      @resolver.variable_offset = build_config.variable_offset
      @resolver.dispatcher_offset = dispatcher_offset
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
      build_config.reserved_image = 0.chr * (build_config.reserved_var_count * @linker_options.var_byte_size)
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
          offs = offs + lgth + @linker_options.var_byte_size
        end
      end
      
      build_config.string_constants = cons
    end
    def build_constant_data(build_config)
      cons = ""
      
      build_config.string_constants.each do |k,v|
        lgth = Converter.int2bin(v[:length], @linker_options.var_size_code)
        cons << "#{lgth}#{v[:text]}"
      end
      
      if (cons.length > 0) && ((cons.length % @linker_options.var_byte_size) > 0)
        cons << (0.chr * (4 - (cons.length % @linker_options.var_byte_size)))
      end
      
      cons = !cons.empty? ? build_config.reserved_image + cons : ""
      
      build_config.constant_image = cons
    end
    def calc_variable_offset(build_config)
      build_config.variable_offset = (build_config.reserved_image + build_config.constant_image).length
    end
    def calc_dynamic_area(build_config)
      build_config.dynamic_area = build_config.variable_offset + (build_config.root_var_count * @linker_options.var_byte_size)
    end
    def build_class_hierarchy(build_config)
      build_config.function_names = build_config.symbols.get_function_names
      build_config.classes = build_config.symbols.get_classes_hierarchy
    end
    
    public
    def link(build_config)
      symbol_refs = build_config.symbol_refs
      codeset = build_config.codeset
      
      build_root_var_indices build_config
      build_reserved_image build_config
      build_string_constants build_config
      build_constant_data build_config
      calc_variable_offset build_config
      calc_dynamic_area build_config
      build_class_hierarchy build_config
      
      sections = 
        {
          "head" => 
            CodeSection.new(
              "head", 
              CodeSection::OTHER, 
              Code.align(hex2bin("B8#{"0" * @linker_options.var_byte_size * 2}50C3"), 16)
            ), 
          "libs" => CodeSection.new("libs", CodeSection::CODE, build_config.kernel.code), 
          "subs" => CodeSection.new("subs", CodeSection::CODE, Code.align(codeset.render(:subs), 16)), 
          "disp" => CodeSection.new("disp", CodeSection::CODE, ""), 
          "init" => CodeSection.new("init", CodeSection::CODE, ""), 
          "main" => CodeSection.new("main", CodeSection::CODE, codeset.render(:main) + Elang::Converter.hex2bin("CD20")), 
          "cons" => CodeSection.new("data", CodeSection::DATA, build_config.constant_image)
        }
      
      
#puts
#puts "classes:"
#puts build_config.classes.inspect
      configure_dispatcher build_config
      asm = @dispatcher.build_obj_method_dispatcher(sections["head"].size + sections["libs"].size, sections["subs"].size)
      sections["disp"].data = Code.align(asm.code, 16)
      mapper_method = asm.instructions.map{|x|x.to_s}.join("\r\n")
#puts
#puts "*** OBJECT METHOD MAPPER ***"
#puts mapper_method
#puts
      
      @linker_options.setup_generator.generate_code_initializer build_config, sections
      
      main_offset = build_config.code_origin + ["head", "libs", "subs", "disp"].map{|x|sections[x].size}.sum
      sections["head"].data[1, @linker_options.var_byte_size] = Elang::Converter.int2bin(main_offset, @linker_options.var_size_code)
      
      if sections["libs"].size > 0
        build_config.kernel.functions.each do |k,v|
          v[:offset] += sections["head"].size
        end
      end
      
      build_config.symbols.items.each do |s|
        if s.is_a?(Function)
          s.offset = s.offset + sections["head"].size + sections["libs"].size
        end
      end
      
      configure_resolver build_config, @dispatcher.dispatcher_offset
      @resolver.resolve_references :subs, sections["subs"].data, symbol_refs, sections["head"].size + sections["libs"].size
      @resolver.resolve_references :init, sections["init"].data, symbol_refs, sections["head"].size + sections["libs"].size + sections["subs"].size + sections["disp"].size
      @resolver.resolve_references :main, sections["main"].data, symbol_refs, sections["head"].size + sections["libs"].size + sections["subs"].size + sections["disp"].size + sections["init"].size
      
      sections.map{|k,v|v.data}.join
    end
  end
end
