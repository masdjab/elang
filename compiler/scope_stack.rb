module Elang
  class ScopeStack
    def initialize
      @scope_stack = []
    end
    def current_scope
      !@scope_stack.empty? ? @scope_stack.last : Scope.new
    end
    def enter_scope(scope)
      @scope_stack << scope
    end
    def leave_scope
      @scope_stack.pop if !@scope_stack.empty?
    end
  end
end
