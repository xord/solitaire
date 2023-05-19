using RubySketch


class Button < Sprite

  def initialize(label, rgb, *args, **kwargs, &block)
    super *args, **kwargs, &block
    @label, @rgb     = label, rgb
    @click, @enabled = nil, true
    setup
  end

  def clicked(&block)
    @click = block
    nil
  end

  def enable(state = true)
    @enabled = state
  end

  def disable()
    enable false
  end

  def enabled?()
    @enabled
  end

  def disabled?()
    !enabled?
  end

  private

  def setup()
    pressing = false
    mousePressed  {pressing = true}
    mouseReleased {pressing = false}

    draw do
      offset, round = 5, 5
      y       = pressing ? (offset - 2) : 0
      h       = self.h - y
      offset -= y
      fill *@rgb.map {|n| n - 20}
      rect 0, y, w, h, round
      fill *@rgb
      rect 0, y, w, h - offset, round
      fill enabled? ? 255 : 180
      textAlign CENTER, CENTER
      text @label, 0, y, w, h - offset
    end

    mouseClicked do
      if enabled?
        @click.call if @click
      else
        shake
      end
    end
  end

  def shake(strength = 10)
    strength = strength.to_f
    x        = self.x
    animate 0.3 do |t, finished|
      self.x = x + (finished ? 0 : strength * (1.0 - t))
      strength *= -1
    end
  end

end# Button
