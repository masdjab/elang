module Assembly
  module ObjectFile
    class Section
      attr_reader   :name, :symbols
      attr_accessor :data
      
      private
      def initialize(name)
        @name = name
        @data = ""
        @symbols = []
      end
      def length
        @data.length
      end
      
      public
      def write(text)
        @data << text
      end
    end
    
    class ObjectFile
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
        [
          align(@sections[:libs].data), 
          align(@sections[:procs].data), 
          align(@sections[:main].data), 
          align(@sections[:text].data)
        ].join
      end
      def save(filename)
        f = File.new(filename, "wb")
        f.write image
        f.close
      end
    end
  end
end
