module Elang
  module Codeset
    class Base
      attr_reader :code, :branch
      
      def initialize
        self.clear
        self.enter_subs
        self.leave_subs
      end
      def enter_subs
        @branch = :subs
      end
      def leave_subs
        @branch = :main
      end
      def append(code)
        @code[@branch] << code if !code.empty?
      end
      def length
        @code[@branch].length
      end
      def clear
        @code = {main: "", subs: ""}
      end
      def empty?
        @code[:main].empty? && @code[:subs].empty?
      end
      def render(branch = nil)
        @code[branch ? branch : @branch]
      end
    end
  end
end
