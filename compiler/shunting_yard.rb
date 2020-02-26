module Elang
  class ShuntingYard
    PRECEDENCE = 
      {
        :dot        => {index: 15, dir: 0, name: ".  member access"}, 
        :star       => {index: 14, dir: 0, name: "*  multiplication"}, 
        :slash      => {index: 14, dir: 0, name: "/  division"}, 
        :percent    => {index: 14, dir: 0, name: "%  modulus"}, 
        :plus       => {index: 12, dir: 0, name: "+  addition"}, 
        :minus      => {index: 12, dir: 0, name: "-  subtraction"}, 
        :ltlt       => {index: 11, dir: 0, name: "<< shift left"}, 
        :gtgt       => {index: 11, dir: 0, name: ">> shift right"}, 
        :equal      => {index: 10, dir: 0, name: "== equal"}, 
        :not_equal  => {index: 10, dir: 0, name: "!= not equal"}, 
        :and        => {index: 9,  dir: 0, name: "&  bitwise and"}, 
        :xor        => {index: 8,  dir: 0, name: "^  bitwise xor"}, 
        :or         => {index: 7,  dir: 0, name: "|  bitwise or"}, 
        :andand     => {index: 5,  dir: 0, name: "&& logical and"}, 
        :oror       => {index: 4,  dir: 0, name: "|| logical or"}, 
        #:assign     => {index: 3,  dir: 1, name: "=  assignment"}, 
        :assign     => {index: 3,  dir: 0, name: "=  assignment"}, 
        #:comma      => {index: 1,  dir: 0, name: ",  comma"}, 
      }
    
    
    def initialize
      @source = nil
    end
    def raize(msg, node = nil)
      if node
        raise ParsingError.new(msg, node.row, node.col, @source)
      else
        raise ParsingError.new(msg, nil, nil, @source)
      end
    end
    def make_operations(rpns)
      operations = []
      
      rpns.each do |rpn|
        if rpn.is_a?(Array)
          if !operations.empty?
            if operations.last.is_a?(AstNode) && (operations.last.type == :identifier)
              fnc_node = operations.pop
              dot_node = AstNode.new(fnc_node.row, fnc_node.col, :dot, ".")
              operations << Operation.new(dot_node, fnc_node, rpn, nil)
            else
              raize "Unexpected array #{rpn.inspect} after #{operations.last.inspect}"
            end
          else
            operations << make_operations(rpn)
          end
        elsif rpn.is_a?(AstNode)
          if PRECEDENCE.key?(rpn.type)
            v2 = operations.pop
            v1 = operations.pop
            
            if rpn.type != :dot
              operations << Operation.new(rpn, v1, v2)
            elsif v2.is_a?(Operation) && (v2.cmd.type == :dot)
              operations << Operation.new(rpn, v2.op1, v2.op2, v1)
            else
              operations << Operation.new(rpn, v2, [], v1)
            end
          else
            operations << rpn
          end
        elsif rpn.is_a?(Operation)
          operations << rpn
        else
          raize "Unexpected rpn type: #{rpn.class}", rpn
        end
      end
      
      operations
    end
    def make_expressions(fetcher)
      operations = []
      stack = []
      
      while item = fetcher.element
        begin
          if item.is_a?(AstNode)
            if PRECEDENCE.key?(item.type)
              item = fetcher.fetch
              
              while !stack.empty?
                pr1 = PRECEDENCE[stack.first.type][:index]
                pr2 = PRECEDENCE[item.type][:index]
                dir = PRECEDENCE[item.type][:dir]
                
                if (pr2 < pr1) || ((pr2 == pr1) && (dir == 0))
                  operations << stack.shift
                else
                  break
                end
              end
              
              stack.insert(0, item)
            elsif item.type == :lbrk
              identifier = fetcher.prev
              fetcher.fetch
              sub_expression = parse_expression(fetcher)
              
              if !identifier.nil? && identifier.is_a?(AstNode) && (identifier.type == :identifier)
                operations << sub_expression
              else
                operations += sub_expression
              end
            elsif item.type == :rbrk
              fetcher.fetch
              break
            elsif item.type == :comma
              fetcher.fetch
            elsif [:lf, :cr, :crlf].include?(item.type)
              fetcher.fetch
              break
            elsif (item.type == :identifier) && (item.text == "end")
              fetcher.fetch
              break
            else
              operations << fetcher.fetch
            end
          else
            operations << fetcher.fetch
          end
        rescue Exception => ex
          puts "operations: #{Lexer.sexp_display(operations)}"
          raise ex
        end
      end
      
      (operations + stack)
    end
    def parse_expression(fetcher)
      make_operations make_expressions(fetcher)
    end
    def fetch_expressions(fetcher, source = nil)
      @source = source
      parse_expression(fetcher)
    end
  end
end
