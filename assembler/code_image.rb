module Elang
  module Assembler
    module CodeImage
      class Section
        attr_reader   :name, :symbols
        attr_accessor :data
        
        private
        def initialize(name)
          @name = name
          @data = ""
          @symbols = []
        end
        
        public
        def length
          @data.length
        end
        def write(text)
          @data << text
        end
      end
      
      class CodeImage
        attr_reader :sections
        
        def initialize
          @sections = 
            {
              :libs   => Section.new(:libs), 
              :procs  => Section.new(:procs), 
              :main   => Section.new(:main), 
              :text   => Section.new(:text)
            }
        end
        def align(image)
          if ((length = image.length) % 16) == 0
            image
          else
            image + (0.chr * (16 - (length % 16)))
          end
        end
        def image
          code = [:libs, :procs, :main].map{|x|@sections[x].data}.join
          text = @sections[:text].data
          
          align(code) + text
        end
        def save(filename)
          f = File.new(filename, "wb")
          f.write image
          f.close
        end
      end
    end
  end
end
