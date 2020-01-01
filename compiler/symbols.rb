module Elang
  class Symbols
    # path format:
    # - main var: module::module.name
    # - global var: module::module$name
    # - local var: module::module#function.name
    # - instance var: module::module::class#function@name
    # - class var: module::module::class@@name
    # - singleton var: module::module::class@name
    
    def initialize
      @symbols = []
    end
    def find_exact(context, name)
      @symbols.find{|x|(x.scope == context) && (x.name == name)}
    end
    def find_nearest(context, name)
      alt1 = nil
      alt2 = nil 
      alt3 = nil
      func_context = context ? context : ""
      
      if chpos = func_context.index("#")
        func_context = func_context[0...chpos]
      end
      
      @symbols.each do |x|
        if x.name == name
          if x.scope == context
            alt1 = x
          elsif !x.scope.nil?
            if x.is_a?(Elang::Function) && (x.scope == func_context)
              alt2 = x
            end
          else
            alt3 = x
          end
        end
      end
      
      alt1 ? alt1 : alt2 ? alt2 : alt3
    end
    def find_string(str)
      @symbols.find{|x|x.is_a?(Constant) && (x.value == str)}
    end
    def item(index)
      @symbols[index]
    end
    def items
      @symbols
    end
    def count
      @symbols.count
    end
    def add(item)
      if self.find_exact(item.scope, item.name)
        raise "Symbol '#{item.name}' already defined"
      else
        @symbols << item
      end
    end
  end
end
