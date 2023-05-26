using RubySketch


class Shake

  def initialize(length, vector)
    @length, @vector = length, vector
  end

  def update()
    @length *=  0.8 if @length
    @vector *= -0.8 if @vector
    v = vector
    @length = @vector = nil if v && v.mag < 1
  end

  def vector()
    return nil unless @length || @vector
    v  = @vector&.dup&.rotate(rand -20.0...20.0) || Vector.random2D
    v *= @length if @length
    v
  end

end# Shake


def shake(obj, length = nil, vector: nil)
  shake = Shake.new length, vector
  pos   = obj.pos.dup
  fun = -> do
    v = shake.vector
    break obj.pos = pos unless v
    obj.pos = pos + v
    shake.update
    delay {fun.call}
  end
  fun.call
end

def shakeScreen(length = nil, vector: nil)
  $shake = Shake.new length, vector
end

def drawShake()
  v = $shake&.vector
  translate v.x, v.y if v
  $shake&.update
end
