module Elang
  class ParsingError < RuntimeError
    attr_reader :message
    def initialize(msg, node = nil, code_lines)
      if node
        @message = "#{msg} at #{node.row}, #{node.col}"
      else
        @message = msg
      end
    end
  end
end
