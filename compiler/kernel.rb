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
      
      lib_functions = {}
      eos_char = 0.chr
      table_offset = Elang::Converter.bin2int(buff[0, 2])
      image_offset = 16
      last_offset = buff.length - 1
      read_offset = table_offset
      
      while read_offset < last_offset
        begin
          func_address = Elang::Converter.bin2int(buff[read_offset, 2]) - image_offset
          eos_position = buff.index(eos_char, read_offset + 2)
          func_name = buff[(read_offset + 2)...eos_position]
          lib_functions[func_name] = {name: func_name, offset: func_address}
          read_offset = read_offset + 2 + func_name.length + 1
        rescue Exception => ex
          last_proc = !lib_functions.empty? ? lib_functions.values.last : nil
          last_name = last_proc ? last_proc[:name] : "(None)"
          puts "Last processed function names: #{lib_functions.values[-5..-1].map{|x|x[:name]}.join(", ")}"
          puts "Total processed: #{lib_functions.count}"
          raise ex
        end
      end
      
      self.new lib_functions, Code.align(buff[image_offset...table_offset], 16)
    end
  end
end
