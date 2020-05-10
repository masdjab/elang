module Elang
  class BuildConfig
    attr_accessor \
      :kernel, :language, :symbols, :symbol_refs, :codeset, :code_origin, 
      :root_var_count, :classes, :function_names, :variable_offset, 
      :string_constants, :constant_image, :dynamic_area, :reserved_var_count, 
      :reserved_image, :first_block_offs, :heap_size, :var_byte_size, 
      :var_size_code, :reference_resolver, :method_dispatcher, :output_formatter, 
      :elang_lib
    
    def initialize
      @kernel = nil
      @language = nil
      @symbols = nil
      @symbol_refs = nil
      @codeset = nil
      @code_origin = 0
      @root_var_count = 0
      @classes = {}
      @function_names = []
      @variable_offset = 0
      @string_constants = {}
      @constant_image = ""
      @dynamic_area = 0
      @reserved_var_count = 0
      @reserved_image = ""
      @first_block_offs = 0
      @heap_size = 0
      @var_byte_size = 0
      @var_size_code = nil
      @reference_resolver = nil
      @method_dispatcher = nil
      @output_formatter = nil
      @elang_lib = nil
    end
  end
end
