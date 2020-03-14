module Elang
  module Lex
    class Node
      attr_reader   :row, :col, :source
      attr_accessor :type, :text
      
      def initialize(row, col, source, type, text)
        @row = row
        @col = col
        @source = source
        @type = type
        @text = text
      end
      def to_s
        @text
      end
      def self.any_to_s(x)
        if x.nil?
          "nil"
        elsif x.is_a?(::Symbol)
          x.inspect
        elsif x.is_a?(::String)
          x
        elsif x.is_a?(Lex::Node)
          x.text
        elsif x.is_a?(::Array)
          "[#{x.map{|x|any_to_s(x)}.join(",")}]"
        elsif x.is_a?(::Hash)
          "{#{x.map{|k,v|"#{any_to_s(k)} => #{any_to_s(v)}"}.join(",")}}"
        elsif x.respond_to?(:to_a)
          any_to_s(x.to_a)
        elsif x.respond_to?(:to_s)
          x.to_s
        else
          x.inspect
        end
      end
      def self.any_to_a(x)
        if x.is_a?(::Array)
          x.map{|x|any_to_a(x)}
        elsif x.respond_to?(:to_a)
          any_to_s(x.to_a)
        else
          x
        end
      end
    end
    
    class Function
      attr_reader :receiver, :name, :params, :body
      def initialize(receiver, name, params, body)
        @receiver, @name, @params, @body = receiver, name, params, body
      end
      def to_a
        ["def", @receiver, @name, @params, @body]
      end
    end
    
    class Class
      attr_reader :name, :parent, :body
      def initialize(name, parent, body)
        @name, @parent, @body = name, parent, body
      end
      def to_a
        ["class", @name, @parent, @body]
      end
    end
    
    class Values
      attr_reader :items, :encloser1, :encloser2, :assign
      def initialize(items, encloser1, encloser2, assign = nil)
        @items, @encloser1, @encloser2, @assign = items, encloser1, encloser2, assign
      end
      def to_a
        @items
      end
    end
    
    class Array
      attr_reader :values
      def initialize(values)
        @values = values
      end
      def to_a
        @values
      end
    end
    
    class Hash
      attr_reader :values
      def initialize(values)
        @values = values
      end
      def to_a
        @values
      end
    end
    
    class Send
      attr_reader :receiver, :cmd, :args
      def initialize(receiver, cmd, args)
        @receiver, @cmd, @args = receiver, cmd, args
      end
      def to_a
        [".", @receiver, @cmd, @args]
      end
    end
    
    class IfBlock
      attr_reader :if_node, :condition, :body1, :body2
      def initialize(if_node, condition, body1, body2)
        @if_node, @condition, @body1, @body2 = if_node, condition, body1, body2
      end
      def to_a
        [@if_node, @condition, @body1, @body2]
      end
    end
    
    class LoopBlock
      attr_reader :body
      def initialize(body)
        @body = body
      end
      def to_a
        ["loop", @body]
      end
    end
    
    class WhileBlock
      attr_reader :condition, :body
      def initialize(condition, body)
        @condition = condition
        @body = body
      end
      def to_a
        ["while", @condition, @body]
      end
    end
    
    class ForBlock
      attr_reader :variable, :iterator, :body
      def initialize(variable, iterator, body)
        @variable = variable
        @iterator = iterator
        @body = body
      end
      def to_a
        ["for", @variable, @iterator, @body]
      end
    end
  end
end
