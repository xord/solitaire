using RubySketch


class Shake

  def initialize(length, vector)
    @length, @vector = length, vector
  end

  def draw()
    v = vector
    translate v.x, v.y if v
    @length *=  0.8 if @length
    @vector *= -0.8 if @vector
    @length = @vector = nil if v && v.mag < 1
  end

  private

  def vector()
    return nil unless @length || @vector
    v  = @vector&.dup&.rotate(rand -20.0...20.0) || Vector.random2D
    v *= @length if @length
    v
  end

end# Shake


def shake(length = nil, vector: nil)
  $shake = Shake.new length, vector
end

def drawShake()
  $shake&.draw
end
