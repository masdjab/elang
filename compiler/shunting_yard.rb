module Elang
  class ShuntingYard
    PRECEDENCE = 
      {
        :dot        => {index: 15, dir: 0, name: ".  member access"}, 
        :star       => {index: 14, dir: 0, name: "*  multiplication"}, 
        :slash      => {index: 14, dir: 0, name: "/  division"}, 
        :percent    => {index: 14, dir: 0, name: "%  modulus"}, 
        :plus       => {index: 12, dir: 0, name: "+  addition"}, 
        :minus      => {index: 12, dir: 0, name: "-  subtraction"}, 
        :ltlt       => {index: 11, dir: 0, name: "<< shift left"}, 
        :gtgt       => {index: 11, dir: 0, name: ">> shift right"}, 
        :equal      => {index: 10, dir: 0, name: "== equal"}, 
        :not_equal  => {index: 10, dir: 0, name: "!= not equal"}, 
        :lt         => {index: 10, dir: 0, name: "<  less than"}, 
        :gt         => {index: 10, dir: 0, name: ">  greater than"}, 
        :le         => {index: 10, dir: 0, name: "<= less than or equal"}, 
        :ge         => {index: 10, dir: 0, name: ">= greater than or equal"}, 
        :and        => {index: 9,  dir: 0, name: "&  bitwise and"}, 
        :xor        => {index: 8,  dir: 0, name: "^  bitwise xor"}, 
        :or         => {index: 7,  dir: 0, name: "|  bitwise or"}, 
        :andand     => {index: 5,  dir: 0, name: "&& logical and"}, 
        :oror       => {index: 4,  dir: 0, name: "|| logical or"}, 
        #:assign     => {index: 3,  dir: 1, name: "=  assignment"}, 
        :assign     => {index: 3,  dir: 0, name: "=  assignment"}, 
        #:comma      => {index: 1,  dir: 0, name: ",  comma"}, 
      }
    
    
    def raize(msg, node = nil)
      if node
        raise ParsingError.new(msg, node.row, node.col, node.source)
      else
        raise ParsingError.new(msg, nil, nil, nil)
      end
    end
    def takeout(nodes)
      nodes
    end
    def reverse_rpns(rpns)
      operations = []
      
      rpns.each do |rpn|
        if rpn.is_a?(Array)
          operations << reverse_rpns(rpn)
        elsif rpn.is_a?(Lex::Node) && PRECEDENCE.key?(rpn.type)
          v2 = operations.pop
          v1 = operations.pop
          operations << Lex::Send.new(v1, rpn, [v2])
        else
          operations << rpn
        end
      end
      
      takeout operations
    end
    def create_rpns(nodes)
      operations = []
      stack = []
      
      nodes.each do |item|
        if item.is_a?(Array)
          operations << create_rpns(item)
        elsif item.is_a?(Lex::Node) && PRECEDENCE.key?(item.type)
          while !stack.empty?
            pr1 = PRECEDENCE[stack.first.type][:index]
            pr2 = PRECEDENCE[item.type][:index]
            dir = PRECEDENCE[item.type][:dir]
            
            if (pr2 < pr1) || ((pr2 == pr1) && (dir == 0))
              operations << stack.shift
            else
              break
            end
          end
          
          stack.insert(0, item)
        else
          operations << item
        end
      end
      
      (operations + stack)
    end
    def process(nodes)
      nodes = reverse_rpns(create_rpns(nodes))
    end
  end
end
