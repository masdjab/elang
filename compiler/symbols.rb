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
      Constant.reset_index
      Function.reset_index
      Variable.reset_index
      ClassVariable.reset_index
      ClassFunction.reset_index
      
      @symbols = []
    end
    def find_matching(context, name)
      alt1 = nil
      alt2 = nil 
      alt3 = nil
      
      @symbols.each do |x|
        if x.name == name
          if x.scope.to_s == context.to_s
            alt1 = x
          elsif x.is_a?(InstanceVariable) && (x.scope.cls == context.cls)
            alt1 = x
          elsif x.is_a?(Function) && (x.scope.cls == context.cls)
            alt2 = x
          elsif x.scope.root?
            alt3 = x
          end
        end
      end
      
      [alt1, alt2, alt3]
    end
    def find_exact(context, name)
      find_matching(context, name)[0]
    end
    def find_nearest(context, name)
      m = find_matching(context, name)
      m[0] ? m[0] : m[1] ? m[1] : m[2]
    end
    def find_string(str)
      @symbols.find{|x|x.is_a?(Constant) && (x.value == str)}
    end
    def find_function(name)
      @symbols.find{|x|x.is_a?(Function) && (x.name == name)}
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
