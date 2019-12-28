module Lang
  class SourceParser
    def initialize(source)
      @line_parser = Parser::LineParser.new(source)
    end
    def parse
      while !@line_parser.eof?
        if !(list = @line_parser.parse).nil?
          if !list.empty?
            puts list.map{|i|i.type}.join
          end
        end
      end
    end
  end
end
