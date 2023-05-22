using RubySketch


class Dialog < Scene

  def initialize(background: 0, alpha: 100, z: 1000)
    super
    @background, @alpha = background, 0
    overlay.z = z
    animate 0.2 do |t|
      @alpha = alpha * t
    end
  end

  def sprites()
    super + [overlay, *buttons]
  end

  def addButton(label, *args, **kwargs, &block)
    Button.new(label, *args, **kwargs).tap do |b|
      b.z = overlay.z
      b.clicked &block
      buttons.push b
      addSprite b if active?
    end
    updateLayout
  end

  def close()
    delay {parent.remove self}
  end

  def draw()
    sprite overlay, *buttons
    super
  end

  def resized(w, h)
    updateLayout
  end

  private

  MARGIN = 10

  def buttons()
    @buttons ||= []
  end

  def overlay()
    @overlay ||= Sprite.new(0, 0, width, height).tap do |sp|
      sp.update do
        sp.w = width
        sp.h = height
      end
      sp.draw do
        fill *@background, @alpha
        rect 0, 0, sp.w, sp.h
      end
    end
  end

  def cancelButton()
    @cancelButton ||= Button.new('CLOSE', width: 3, fontSize: 28).tap do |sp|
      sp.z = overlay.z
      sp.clicked {close}
    end
  end

  def updateLayout()
    w, h      = width, height
    allHeight = buttons.map(&:height).reduce {|a, b| a + MARGIN + b} || 0
    y         = (h - allHeight) / 2
    buttons.each do |b|
      b.x = (w - b.w) / 2
      b.y = y
      y  += b.h + MARGIN
    end
  end

end# Dialog
