def now()
  Time.now.to_f
end

def unique()
  Object.new.object_id
end


module HasSprite

  extend Forwardable

  def_delegators :sprite,
    :pos, :pos=, :x, :x=, :y, :y=, :size, :w, :h, :angle, :angle=

end# HasSprite
