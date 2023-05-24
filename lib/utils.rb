def now()
  Time.now.to_f
end

def unique()
  Object.new.object_id
end


module Processing
  class Vector
    def xy()
      self.class.new x, y
    end
  end
end


module HasSprite

  extend Forwardable

  def_delegators :sprite,
    :pos, :pos=, :x, :x=, :y, :y=, :z, :z=, :center, :center=,
    :size, :width, :width=, :height, :height=, :depth, :w, :w=, :h, :h=, :d,
    :angle, :angle=

  def hit?(x, y)
    s = sprite
    s.x <= x && x < (s.x + s.w) && s.y <= y && y < (s.y + s.h)
  end

end# HasSprite
