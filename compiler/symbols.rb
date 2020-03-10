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
    def self.create_class_id(cls)
      if cls.name == "Integer"
        nil
      elsif Class::ROOT_CLASS_IDS.key?(cls.name)
        Class::ROOT_CLASS_IDS[cls.name]
      else
        Class::USER_CLASS_ID_BASE + (cls.index * 2)
      end
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
      
      item
    end
    def register_variable(scope, name)
      self.add Elang::Variable.new(scope, name)
    end
    def register_instance_variable(scope, name)
      scope = Scope.new(scope.cls)
      ivars = self.items.select{|x|(x.scope.cls == scope.cls) && x.is_a?(InstanceVariable)}
      
      if (variable = ivars.find{|x|x.name == name}).nil?
        index = ivars.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        variable = self.add(InstanceVariable.new(scope, name, index))
      end
      
      variable
    end
    def register_class(name, parent)
      scope = Scope.new
      clist = self.items.select{|x|x.is_a?(Class)}
      
      if (cls = clist.find{|x|x.name == name}).nil?
        idx = clist.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        cls = self.add(Class.new(scope, name, parent, idx))
      end
      
      cls
    end
    def register_class_variable(scope, name)
      self.add ClassVariable.new(scope, name)
    end
    def register_function(scope, rcvr_name, func_name, func_args)
      if (fun = self.items.find{|x|(x.name == func_name) && x.is_a?(Function) && (x.scope.to_s == scope.to_s)}).nil?
        fun = self.add(Function.new(scope, rcvr_name, func_name, func_args, 0))
      end
      
      fun
    end
    def get_function_names
      predefined = Function::PREDEFINED_FUNCTION_NAMES
      func_names = self.items.select{|x|x.is_a?(Function)}.map{|x|x.name}.uniq
      predefined + (func_names - predefined)
    end
    def get_global_variables
      self.items.select{|s|s.is_a?(Variable) && s.scope.root?}
    end
    def get_instance_variables(cls)
      if cls.parent
        parent = self.items.find{|x|x.is_a?(Class) && (x.name == cls.parent)}
        parent_iv = get_instance_variables(parent)
      else
        parent_iv = []
      end
      
      self_iv = self.items.select{|x|x.is_a?(InstanceVariable) && (x.scope.cls == cls.name)}.map{|x|x.name}
      
      parent_iv + self_iv
    end
    def get_instance_methods(cls)
      functions = get_function_names
      
      self.items
        .select{|x|x.is_a?(Function) && (x.scope.cls == cls.name) && x.receiver.nil?}
        .map{|x|{id: functions.index(x.name), name: x.name, offset: x.offset}}
    end
    def get_classes_hierarchy
      classes = {}
      
      self.items.each do |s|
        if s.is_a?(Class)
          if !classes.key?(s.name)
            classes[s.name] = 
              {
                :clsid  => self.class.create_class_id(s), 
                :parent => s.parent, 
                :i_vars => get_instance_variables(s), 
                :i_funs => get_instance_methods(s)
              }
          end
        end
      end
      
      classes
    end
  end
end
