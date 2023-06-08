using RubySketch


class Button < Sprite

  include CanDisable

  def initialize(
    label = nil, *args,
    icon: nil, rgb: nil, width: 1, fontSize: 24, round: 5, **kwargs,
    &block)

    raise if !label && !icon

    super 0, 0, 44 * width, 44, *args, **kwargs, &block
    @label, @icon, @rgb, @fontSize, @round = label, icon, rgb, fontSize, round
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

    mousePressed do
      pressing = true
    end

    mouseReleased do
      pressing = false
      if includeMouse?
        if enabled?
          @click&.call
        else
          shake
        end
        sound.play gain: 0.5
      end
    end

    mouseDragged do
      pressing = includeMouse?
    end

    draw do
      offset  = 5
      light   = [@rgb || skin.buttonColor].flatten
      dark    = light.map {|n| n - 32}
      y       = pressing ? (offset - (enabled? ? 2 : 3.5)) : 0
      h       = self.h - y
      offset -= y
      fill *dark
      rect 0, y, w, h, *@round
      fill *light
      h -= offset
      rect 0, y, w, h, *@round
      fill *(enabled? ? [255] : dark)
      if @label
        textAlign CENTER, CENTER
        textSize @fontSize
        text @label, 0, y, w, h
      elsif @icon
        imageMode CENTER
        drawImage @icon, w / 2, y + h / 2, @icon.width / 2, @icon.height / 2
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

  def sound()
    @sound ||= loadSound dataPath 'button.mp3'
  end

  def includeMouse?()
    (0...width).include?(mouseX) && (0...height).include?(mouseY)
  end

end# Button
