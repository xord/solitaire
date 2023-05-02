using RubySketch


class GameObject
  def initialize(width, height, z: 0, color: 255)
    @x, @y, @z = 0, 0, z
    @w, @h = width, height
    @color = color
  end

  attr_accessor :x, :y, :z, :w, :h, :color

  def pos()
    [x, y, z]
  end

  def pos=(pos)
    raise ArgumentError unless [2, 3].include?(pos.size)
    x, y, z = pos
    self.x, self.y = x, y
    self.z = z if z
  end

  def frame=(frame)
    raise ArgumentError unless frame.size == 4
    self.x, self.y, self.w, self.h = frame
  end

  def draw()
    rect 0, 0, w, h
  end

  def draw!()
    push do
      translate x, y, z
      fill *color
      noStroke
      draw
    end
  end

  def hit?(x, y)
    @x <= x && x < (@x + @w) && @y <= y && y < (@y + @h)
  end
end
