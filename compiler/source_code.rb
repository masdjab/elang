module Elang
  class CodeLineInfo
    attr_reader :row, :min, :max
    
    def initialize(row, min, max)
      @row = row
      @min = min
      @max = max
    end
    def len
      @max - @min + 1
    end
  end
  
  
  class StringSourceCode
    attr_reader :text, :lines
    
    def initialize(text)
      @text = text
      @lines = self.class.detect_lines(@text)
    end
    def self.detect_lines(code)
      pos = 0
      row = 1
      lines = []
      
      code.lines.each do |line|
        lines << CodeLineInfo.new(row, pos, pos + line.length - 1)
        row += 1
        pos += line.length
      end
      
      lines
    end
    def line_at(row)
      if line = @lines.find{|x|x.row == row}
        @text[(line.min)..(line.max)]
      end
    end
    def highlight(row, col, radius = 3, line_nums = nil)
      # line_nums: false = hide, nil => auto, int => fixed
      
      snapshot = []
      
      if @lines.is_a?(Array) && !@lines.empty?
        rowid = row
        max_r = @lines.count
        row_f = rowid > radius ? rowid - radius : 1
        row_t = (rowid + radius) <= max_r ? (rowid + radius) : max_r
        lnlen = "#{row_t}".length
        
        if line_nums == false
          ll = 0
          lf = lambda{|x|""}
        elsif line_nums.is_a?(Integer) && (line_nums >= 0)
          ll = line_nums > 0 ? line_nums + 1 : 0
          lf = lambda{|x|"#{x.to_s.rjust(line_nums)} "}
        else
          ll = lnlen > 0 ? lnlen + 1 : 0
          lf = lambda{|x|"#{x.to_s.rjust(lnlen)} "}
        end
        
        snapshot += (row_f..rowid).map{|x|"#{lf.call(x)}#{line_at(x)}"}
        snapshot << $/ if snapshot.last[-1] != $/
        snapshot << (" " * (ll + col - 1)) + "^#{$/}"
        snapshot += ((rowid + 1)..row_t).map{|x|"#{lf.call(x)}#{line_at(x)}"}
      end
      
      snapshot.join
    end
  end
  
  
  class FileSourceCode < StringSourceCode
    attr_reader :file_name
    
    def initialize(file_name)
      @file_name = file_name
      super(File.read(file_name))
    end
  end
  
  
  class ParsingExceptionFormatter
    def format(exception)
      msg = exception.message
      
      if exception.is_a?(ParsingError)
        src = exception.source
        row = exception.row
        col = exception.col
      else
        src, row, col = nil, nil, nil
      end
      
      if !row.nil? && !col.nil?
        if src.nil?
          "#{msg} (#{exception.class}) at #{row}, #{col}"
        else
          file_info = src.is_a?(FileSourceCode) ? " in #{src.file_name}" : ""
          "#{msg} (#{exception.class})#{file_info} at #{row}, #{col}#{$/}#{src.highlight(row, col)}"
        end
      else
        "#{msg} (#{exception.class})"
      end
    end
  end
end
