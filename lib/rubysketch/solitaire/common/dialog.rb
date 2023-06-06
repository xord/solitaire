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

  def addElement(sprite)
    elements.push sprite
    addSprite sprite if active?
    updateLayout
    sprite
  end

  def addLabel(label, rgb: [255], fontSize: 24, align: CENTER)
    bounds = textFont.textBounds label, 0, 0, fontSize
    addElement Sprite.new(0, 0, bounds.w, bounds.h).tap {|sp|
      sp.z = overlay.z
      sp.draw do
        textAlign align, CENTER
        textSize fontSize
        fill *rgb
        text label, 0, 0, sp.w, sp.h
      end
    }
  end

  def addButton(*args, **kwargs, &block)
    addElement Button.new(*args, **kwargs).tap {|b|
      b.z = overlay.z
      b.clicked &block
    }
  end

  def addSpace(height)
    addElement Sprite.new(0, 0, 1, height).tap {|sp|
      sp.draw {}
    }
  end

  def close()
    delay {parent.remove self}
  end

  def sprites()
    super + [overlay, *elements]
  end

  def elements()
    @elements ||= []
  end

  def draw()
    sprite overlay, *elements
    super
  end

  def resized(w, h)
    updateLayout
  end

  def activated()
    super
    parent.pause
  end

  def deactivated()
    parent.resume
    super
  end

  private

  MARGIN = 10

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
    allHeight = elements.map(&:height).reduce {|a, b| a + MARGIN + b} || 0
    y         = (h - allHeight) / 2
    elements.each do |e|
      e.x = (w - e.w) / 2
      e.y = y
      y  += e.h + MARGIN
    end
  end

end# Dialog
