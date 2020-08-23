module Elang
  class ParsingError < Exception
    attr_reader :row, :col, :source
    def initialize(msg, row = nil, col = nil, source = nil)
      @row, @col, @source = row, col, source
      super(msg)
    end
  end
  
  
  class DefaultExceptionFormatter
    def format(exception)
      "#{exception.message} (#{exception.class})"
    end
  end
  
  
  class ExceptionHelper
    def self.show(e, formatter = DefaultExceptionFormatter.new)
      puts e.backtrace.reverse
      puts
      puts formatter.format(e)
      puts
    end
  end
  
  
  class ParsingExceptionFormatter
    def format(exception)
      msg = exception.message
      
      src_info = lambda{|x|x.respond_to?(:file_name) ? " in #{x.file_name}" : ""}
      
      if exception.is_a?(ParsingError)
        src = exception.source
        row = exception.row
        col = exception.col
      else
        src, row, col = nil, nil, nil
      end
      
      sf_info = src.respond_to?(:file_name) ? " in #{src.file_name}" : ""
      rc_info = !row.nil? && !col.nil? ? " at #{row}, #{col}" : ""
      preview = !src.nil? && !col.nil? && !row.nil? ? src.highlight(row, col) : ""
      
      if !preview.gsub("\r", "").gsub("\n", "").empty?
        preview = "#{$/}#{$/}#{preview}"
      end
      
      "#{msg} (#{exception.class})#{sf_info}#{rc_info}#{preview}"
    end
  end
end
