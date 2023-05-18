def now()
  Time.now.to_f
end

def unique()
  Object.new.object_id
end


module HasSprite

  extend Forwardable

  def_delegators :sprite,
    :pos, :pos=, :x, :x=, :y, :y=, :z, :z=, :center, :center=,
    :size, :width, :height, :depth, :w, :h, :d,
    :angle, :angle=

  def hit?(x, y)
    s = sprite
    s.x <= x && x < (s.x + s.w) && s.y <= y && y < (s.y + s.h)
  end

end# HasSprite
