require './compiler/symbols'
require './compiler/ast_node'
require './utils/converter'

module Elang
  class CodeGenerator
    attr_reader :symbols
    
    def initialize
      @symbols = Symbols.new
    end
    def prepare_operand(node, value_index, operand_index)
      reg = ["ax", "cx"][operand_index ? operand_index - 1 : 0]
      
      if (val_node = node[value_index]).is_a?(Array)
        generate_code([val_node])
      elsif val_node.type == :number
        "mov #{reg}, 0#{val_node.text.to_i.to_s(16)}h;"
      elsif val_node.type == :string
        "mov #{reg}, str(#{val_node.text.inspect});"
      elsif val_node.type == :identifier
        "mov #{reg}, #{val_node.text};"
      else
        op_info = operand_index ? " #{operand_index}" : ""
        raise "Invalid operand#{op_info}: #{val_node.inspect}"
      end
    end
    def prepare_operands(node)
      init_ax = prepare_operand(node, 1, 1)
      init_cx = prepare_operand(node, 2, 2)
      init_ax + init_cx
    end
    def handle_assignment(node)
      if !node[1].is_a?(Elang::AstNode) || (node[1].type != :identifier)
        raise "Left operand for assignment must be a symbol, #{node[1].inspect} given"
      end
      
      init_ax = prepare_operand(node, 2, nil)
      
      init_ax + "mov #{node[1].text}, ax;"
    end
    def handle_addition(node)
      prepare_operands(node) + "add ax, cx;"
    end
    def handle_subtraction(node)
      prepare_operands(node) + "sub ax, cx;"
    end
    def handle_multiplication(node)
      prepare_operands(node) + "mul ax, cx;"
    end
    def handle_division(node)
      prepare_operands(node) + "div ax, cx;"
    end
    def handle_numeric_and(node)
      prepare_operands(node) + "and ax, cx;"
    end
    def handle_numeric_or(node)
      prepare_operands(node) + "or ax, cx;"
    end
    def handle_function_def(node)
      params_count = node[2].count
      func_body = generate_code(node[3])
      func_body + "ret" + (params_count > 0 ? " #{params_count * 2}" : "")
    end
    def handle_function_call(node)
      #init_args = node[2].map{|x|prepare_operand(x, 1, 1) + "push ax;"}.join
      init_args = (0...node[2].count).map{|x|prepare_operand(node[2], x, 1) + "push ax;"}.join
      init_args + "call #{node[1].text};"
    end
    def generate_code(nodes)
      binary_code = ""
      
      nodes.each do |node|
        if node.is_a?(Array)
          if !node[0].is_a?(Elang::AstNode)
            raise "Expected identifier, #{node[0].inspect} given"
          elsif node[0].type == :punc
            case node[0].text
            when "="
              binary_code << handle_assignment(node)
            when "+"
              binary_code << handle_addition(node)
            when "-"
              binary_code << handle_subtraction(node)
            when "*"
              binary_code << handle_multiplication(node)
            when "/"
              binary_code << handle_division(node)
            when "&"
              binary_code << handle_numeric_and(node)
            when "|"
              binary_code << handle_numeric_or(node)
            else
              raise "Unknown node type: #{node.inspect}"
            end
          elsif node[0].type == :identifier
            case node[0].text
            when "def"
              binary_code << handle_function_def(node)
            when "call"
              binary_code << handle_function_call(node)
            else
              raise "Cannot handle node: #{node.inspect}"
            end
          else
            raise "Cannot handle node: #{node.inspect}"
          end
        else
          raise "Expected array, #{node.class} given: #{node.inspect}"
        end
      end
      
      binary_code
    end
  end
end
