using RubySketch


class TransitionEffect < Scene

  def initialize(
    nextScene, sec: 1,
     secOut: nil,       secIn: nil,
    easeOut: :expoOut, easeIn: :expoIn,
    &block)

    super()
    @nextScene, @easeOut, @easeIn = nextScene, easeOut, easeIn
    @secOut = secOut || sec / 2.0
    @secIn  = secIn  || sec / 2.0
    @phase  = :out
  end

  attr_reader :phase

  def effect(t)
  end

  def activated()
    super
    start do
      case @phase
      when :out
        pa = parent
        pa.remove self
        @phase = :in
        @nextScene.add self
        pa.transition @nextScene
      when :in
        parent.remove self
      end
    end
  end

  private

  def start(&block)
    sec  = out? ? @secOut  : @secIn
    ease = out? ? @easeOut : @easeIn
    animate sec, ease: ease do |t, finished|
      effect (out? ? t : 1.0 - t)
      block.call if finished
    end
  end

  def out?()
    @phase == :out
  end

end# TransitionEffect


class Fade < TransitionEffect

  def initialize(*args, rgb: 0, **kwargs, &block)
    super(*args, easeIn: :expoOut, **kwargs)
    @rgb, @alpha = rgb, 0
  end

  def effect(t)
    @alpha = 255 * t
  end

  def draw()
    super
    fill *@rgb, @alpha
    noStroke
    rect 0, 0, width, height
  end

end# Fade
