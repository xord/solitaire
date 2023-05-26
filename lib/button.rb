using RubySketch


class Button < Sprite

  include CanDisable

  def initialize(
    label, *args, rgb: 200, width: 1, fontSize: 24, round: 5, **kwargs, &block)

    super 0, 0, 44 * width, 44, *args, **kwargs, &block
    @label, @rgb, @fontSize, @round = label, [rgb].flatten, fontSize, round
    @click = nil
    setup
  end

  def clicked(&block)
    @click = block
    nil
  end

  private

  def setup()
    pressing = false
    mousePressed  {pressing = true}
    mouseReleased {pressing = false}

    draw do
      offset  = 5
      y       = pressing ? (offset - (enabled? ? 2 : 3.5)) : 0
      h       = self.h - y
      offset -= y
      fill *@rgb.map {|n| n - 20}
      rect 0, y, w, h, *@round
      fill *@rgb
      rect 0, y, w, h - offset, *@round
      fill enabled? ? 255 : 180
      textAlign CENTER, CENTER
      textSize @fontSize
      text @label, 0, y, w, h - offset
    end

    mouseClicked do
      if enabled?
        @click.call if @click
      else
        shake
      end
      sound.play gain: 0.5
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

  def sound()
    @sound ||= loadSound 'data/button.mp3'
  end

end# Button
