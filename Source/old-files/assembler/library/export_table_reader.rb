module Elang
  module Library
    class ExportTableReader
      def read(app_section)
        # return hash with fucntion_name as key and functio offset as value
        
        rp = 0
        bl = app_section.body.length
        ff = {}
        
        while (0...bl).include?(rp)
          if app_section.body[rp] != 0.chr
            if !(zp = app_section.body.index(0.chr, rp)).nil?
              fn = app_section.body[rp...zp]
              oo = Converter.dword_to_int(app_section.body[(zp + 1), 4])
              rp = zp + 5
              ff[fn.to_sym] = oo
            else
              break
            end
          else
            break
          end
        end
        
        ff
      end
    end
  end
end
