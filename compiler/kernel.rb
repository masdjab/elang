module Elang
  class Kernel
    attr_reader :functions, :code
    
    def initialize(functions, code)
      @functions = functions
      @code = code
    end
    def self.load_library(libfile)
      file = File.new(libfile, "rb")
      buff = file.read
      file.close
      
      lib_functions = []
      eos_char = 0.chr
      architecture = Elang::Converter.bin2int(buff[0, 2])
      table_offset = Elang::Converter.bin2int(buff[2, 2])
      int_width = {1 => 2, 2 => 4}[architecture]
      image_offset = 16
      last_offset = buff.length - 1
      read_offset = table_offset
      
      while read_offset < last_offset
        begin
          func_address = Elang::Converter.bin2int(buff[read_offset, int_width]) - image_offset
          eos_position = buff.index(eos_char, read_offset + int_width)
          func_name = buff[(read_offset + int_width)...eos_position]
          new_function = SystemFunction.new(func_name, func_address)
          lib_functions << new_function
          yield(new_function) if block_given?
          read_offset = read_offset + int_width + func_name.length + 1
        rescue Exception => ex
          last_proc = !lib_functions.empty? ? lib_functions.last : nil
          last_name = last_proc ? last_proc[:name] : "(None)"
          puts "Last processed function names: #{lib_functions[-5..-1].map{|x|x[:name]}.join(", ")}"
          puts "Total processed: #{lib_functions.count}"
          raise ex
        end
      end
      
      self.new lib_functions, buff[image_offset...table_offset]
    end
  end
end
