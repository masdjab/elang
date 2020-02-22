module Elang
  class ParsingError < StandardError
    attr_reader :message
    
    def initialize(msg, row = nil, col = nil, code_lines = [])
      @message = format_message(msg, row, col, code_lines)
    end
    def line_number(num, len)
      ln = "#{num}"
      (" " * (len - ln.length)) + ln
    end
    def format_message(msg, row, col, code_lines)
      snapshot = []
      
      if row.is_a?(AstNode)
        row, col, code_lines = row.row, row.col, col
      end
      
      if !row.nil? && !col.nil?
        snapshot << "#{msg} at #{row}, #{col}"
        
        if code_lines.is_a?(Array) && !code_lines.empty?
          rowid = row - 1
          max_r = code_lines.count - 1
          row_f = rowid >= 4 ? rowid - 4 : 0
          row_t = (rowid + 4) <= max_r ? (rowid + 4) : max_r
          lilen = "#{row_t}".length
          
          sshot = []
          sshot += (row_f..rowid).map{|x|"#{line_number(x + 1, lilen)} #{code_lines[x][:text]}"}
          sshot << (" " * (lilen + col)) + "^"
          sshot += ((rowid + 1)..row_t).map{|x|"#{line_number(x + 1, lilen)} #{code_lines[x][:text]}"}
          
          snapshot << ""
          snapshot += sshot.map{|x|x.chomp("\n")}
        end
      end
      
      snapshot.join("\r\n")
    end
  end
  
  
  class Exception
    def self.show(e)
      puts e.backtrace.reverse
      puts
      puts e.message
      puts
    end
  end
end
