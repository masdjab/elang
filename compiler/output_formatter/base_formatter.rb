module Elang
  class BaseOutputFormatter
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
      build_config.reserved_image = 0.chr * (build_config.reserved_var_count * build_config.var_byte_size)
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
          pads = (lgth % 2) > 0 ? 1 : 0
          cons[s.name] = {text: text, length: lgth, offset: offs, pads: pads}
          offs = offs + lgth + build_config.var_byte_size + pads
        end
      end
      
      build_config.string_constants = cons
    end
    def build_constant_data(build_config)
      cons = ""
      
      build_config.string_constants.each do |k,v|
        lgth = Converter.int2bin(v[:length], build_config.var_size_code)
        cons << "#{lgth}#{v[:text]}#{0.chr * v[:pads]}"
      end
      
      if (cons.length > 0) && ((cons.length % build_config.var_byte_size) > 0)
        cons << (0.chr * (4 - (cons.length % build_config.var_byte_size)))
      end
      
      cons = !cons.empty? ? build_config.reserved_image + cons : ""
      
      build_config.constant_image = cons
    end
    def calc_variable_offset(build_config)
      build_config.variable_offset = (build_config.reserved_image + build_config.constant_image).length
    end
    def calc_dynamic_area(build_config)
      build_config.dynamic_area = build_config.variable_offset + (build_config.root_var_count * build_config.var_byte_size)
    end
    def build_class_hierarchy(build_config)
      build_config.function_names = build_config.symbols.get_function_names
      build_config.classes = build_config.symbols.get_classes_hierarchy
    end
    def build_preformat_values(build_config)
      build_root_var_indices build_config
      build_reserved_image build_config
      build_string_constants build_config
      build_constant_data build_config
      calc_variable_offset build_config
      calc_dynamic_area build_config
      build_class_hierarchy build_config
    end
  end
  
  public
  def extension
    "bin"
  end
  def format_output(build_config)
    ""
  end
end
