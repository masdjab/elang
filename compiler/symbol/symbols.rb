require_relative 'class'
require_relative 'class_function'
require_relative 'class_variable'
require_relative 'constant'
require_relative 'function'
require_relative 'function_id'
require_relative 'function_parameter'
require_relative 'import_function'
require_relative 'instance_variable'
require_relative 'label'
require_relative 'system_function'
require_relative 'variable'

module Elang
  class Symbols
    private
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
    
    public
    def items
      @symbols
    end
    def [](index)
      @symbols[index]
    end
    def count
      @symbols.count
    end
    def add(item)
      if !item.name.nil? && self.find_exact(item.scope, item.name)
        raise "Symbol '#{item.name}' already defined"
      else
        @symbols << item
      end
      
      item
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
    def register_constant(scope, name, value)
      self.add(Constant.new(scope, name, value))
    end
    def register_variable(context, scope, name)
      self.add Elang::Variable.new(context, scope, name)
    end
    def register_instance_variable(context, scope, name)
      scope = Scope.new(scope.cls)
      ivars = self.items.select{|x|(x.scope.cls == scope.cls) && x.is_a?(InstanceVariable)}
      
      if (variable = ivars.find{|x|x.name == name}).nil?
        index = ivars.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        variable = self.add(InstanceVariable.new(context, scope, name, index))
      end
      
      variable
    end
    def register_class(context, name, parent)
      scope = Scope.new
      clist = self.items.select{|x|x.is_a?(Class)}
      
      if (cls = clist.find{|x|x.name == name}).nil?
        if Class::ROOT_CLASS_IDS.key?(name)
          clsid = Class::ROOT_CLASS_IDS[name]
        else
          clsid = Class::USER_CLASS_ID_BASE + clist.select{|x|!Class::ROOT_CLASS_IDS.key?(x.name)}.count * 2
        end
        
        cls = self.add(Class.new(context, scope, name, parent, clsid))
      end
      
      cls
    end
    def register_class_variable(context, scope, name)
      self.add ClassVariable.new(context, scope, name)
    end
    def register_function(context, scope, rcvr_name, func_name, func_args)
      if (fun = self.items.find{|x|(x.name == func_name) && x.is_a?(Function) && (x.scope.to_s == scope.to_s)}).nil?
        fun = self.add(Function.new(context, scope, rcvr_name, func_name, func_args, 0))
      end
      
      fun
    end
    def register_label(context, scope, name, offset)
      self.add(Label.new(context, scope, name, offset))
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
                :clsid  => s.clsid, 
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
