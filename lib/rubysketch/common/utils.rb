using RubySketch


def ios?()
  RbConfig::CONFIG['CFLAGS'] =~ %r{/Platforms/iPhone(OS|Simulator).platform/}
end

def now()
  Time.now.to_f
end

def unique()
  Object.new.object_id
end

def dataPath(path)
  File.expand_path "../../../data/#{path}", __dir__
end

def resizeImage(image, w, h)
  createGraphics(w, h).tap do |g|
    g.beginDraw do
      g.copy image, 0, 0, image.width, image.height, 0, 0, w, h
    end
  end
end

def move(obj, toPos, seconds, **kwargs, &block)
  from, to = obj.pos.dup, toPos.dup
  animate seconds, **kwargs do |t, *args|
    obj.pos = Vector.lerp(from, to, t)
    block&.call t, *args
  end
end


module Processing
  class Vector
    def xy()
      self.class.new x, y
    end
  end
end


module CanDisable

  def initialize(*a, **k, &b)
    super
    @enabled = true
  end

  def enable(state = true)
    return if state == @enabled
    @enabled = state
    @enabled ? enabled : disabled
  end

  def disable(&block)
    old = enabled?
    enable false
    if block
      begin
        block.call
      ensure
        enable old
      end
    end
  end

  def enabled?()
    @enabled
  end

  def disabled?()
    !enabled?
  end

  def enabled()
  end

  def disabled()
  end

end# CanDisable


module HasSprite

  extend Forwardable

  def_delegators :sprite,
    :pos, :pos=, :x, :x=, :y, :y=, :z, :z=, :center, :center=,
    :left, :left=, :top, :top=, :right, :right=, :bottom, :bottom=,
    :size, :width, :width=, :height, :height=, :depth, :w, :w=, :h, :h=, :d,
    :angle, :angle=

  alias l  left
  alias l= left=
  alias t  top
  alias t= top=
  alias r  right
  alias r= right=
  alias b  bottom
  alias b= bottom=

  def hit?(x, y)
    s = sprite
    s.x <= x && x < (s.x + s.w) && s.y <= y && y < (s.y + s.h)
  end

end# HasSprite
