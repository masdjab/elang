module Elang
  class LinkerOptions
    attr_accessor :var_byte_size, :var_size_code, :reference_resolver, :method_dispatcher, :setup_generator
    
    def initialize
      @var_byte_size = 0
      @var_size_code = nil
      @reference_resolver = nil
      @method_dispatcher = nil
      @setup_generator = nil
    end
  end
end
