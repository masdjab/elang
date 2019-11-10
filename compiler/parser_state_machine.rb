class ParserStateMachine
  def state_hash(item)
    {start: item[0], name: item[1], chars: item[2], paths: item[3], type: item[4]}
  end
  def init_states
    if @init_states.nil?
      raw_states = 
        [
          [1, :zero_beg, '0', [:zero_mid, :one_to_nine, :hex_x, :dot], :int], 
          [0, :zero_mid, '0', [:zero_mid, :one_to_nine, :dot], :int], 
          [1, :one_to_nine, '123456789', [:zero_mid, :one_to_nine, :dot], :int], 
          [1, :dot, '.', [:zero_to_nine_f], nil], 
          [0, :zero_to_nine, '0123456789', [:zero_to_nine], :int], 
          [0, :zero_to_nine_f, '0123456789', [:zero_to_nine_f], :float], 
          [0, :hex_x, 'x', [:hex_num], nil], 
          [0, :hex_num, '0123456789abcdef', [:hex_num], :hex], 
          [1, :ident_beg, 'abcdefghijklmnopqrstuvwxyz_', [:ident_mid], :ident], 
          [0, :ident_mid, '0123456789abcdefghijklmnopqrstuvwxyz_', [:ident_mid], :ident], 
          [0, :invalid_num, 'abcdefghijklmnopqrstuvwxyz_', [:invalid_num, :invalid_ltr], nil], 
          [0, :invalid_ltr, '0123456789', [:invalid_ltr, :invalid_num], nil]
        ]
      
      @states = raw_states.map{|x|state_hash(x)}
    end
  end
  def start_branches
    @states.select{|x|x[:start] == 1}
  end
  def parse(text)
    if !text.empty?
      init_states
      
      t_len = text.length
      c_pos = 0
      temp = ""
      type = nil
      
      branches = start_branches
      
      while (0...t_len).include?(c_pos)
        current_char = text[c_pos]
        lower_char = current_char.downcase
        
        matched_branch = branches.find{|x|x[:chars].index(lower_char)}
        
        if matched_branch
          temp << current_char
          type = matched_branch[:type]
          branches = @states.select{|x|matched_branch[:paths].include?(x[:name])}
          c_pos += 1
        else
          break
        end
      end
      
      {text: temp, type: type, pos: c_pos}
    end
  end
end
