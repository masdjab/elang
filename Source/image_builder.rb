module Elang
  class ImageBuilder
    def build(app)
      app.functions.map{|x|x.code}.join
    end
  end
end
