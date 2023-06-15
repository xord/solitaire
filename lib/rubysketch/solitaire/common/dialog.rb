using RubySketch


class Dialog < Scene

  def initialize(background: 0, alpha: 100, z: 1000, &block)
    @background, @alpha = background, 0
    @elements = []
    super
    overlay.z = z
    group :vertical, &block if block
    animate 0.2 do |t|
      @alpha = alpha * t
    end
  end

  def group(flow = :horizontal, &block)
    old, @group = @group, []
    block.call self
  ensure
    (old || @elements).push({elements: @group, flow: flow})
    @group = old
    updateLayout
  end

  def addElement(sprite)
    (@group || @elements).push sprite
    sprite.z = overlay.z
    addSprite sprite if active?
    updateLayout
    sprite
  end

  def addLabel(label, rgb: [255], fontSize: 24, align: CENTER)
    bounds = textFont.textBounds label, 0, 0, fontSize
    addElement Sprite.new(0, 0, width - MARGIN * 2, bounds.h).tap {|sp|
      sp.draw do
        r, g, b, a = skin.translucentBackgroundColor
        fill r, g, b, a * 3
        rect 0, -MARGIN / 2, sp.w, sp.h + MARGIN
        textAlign align, CENTER
        textSize fontSize
        fill *rgb
        text label, 0, 0, sp.w, sp.h
      end
    }
  end

  def addButton(*args, **kwargs, &block)
    addElement Button.new(*args, **kwargs).tap {|b|
      b.clicked &block
    }
  end

  def addSpace(height = 0)
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
    f = -> es {es.map {|e| ((e in {elements:})) ? f[elements] : e}}
    f.call(@elements).flatten
  end

  def draw()
    sprite overlay
    super
    sprite *elements
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
      sp.clicked {close}
    end
  end

  def updateLayout()
    element = {elements: @elements, flow: :vertical}
    w, h    = getSize element
    setPosition element, (width - w) / 2, (height - h) / 2, w, h
  end

  def getSize(element)
    if element in {elements:, flow:}
      v     = flow == :vertical
      sizes = elements.map {|e| getSize e}
      sum   = sizes.map {|size| size[v ? 1 : 0]}.reduce {|a, b| a + MARGIN + b} || 0
      max   = sizes.map {|size| size[v ? 0 : 1]}.max || 0
      v ? [max, sum] : [sum, max]
    else
      [element.w, element.h]
    end
  end

  def setPosition(element, x, y, w, h)
    if element in {elements:, flow:}
      v = flow == :vertical
      elements.each do |e|
        ew, eh = getSize e
        ex, ey = v ? [x + (w - ew) / 2, y] : [x, y + (h - eh) / 2]
        setPosition e, ex, ey, ew, eh
        x += ew + MARGIN if !v
        y += eh + MARGIN if  v
      end
    else
      element.x, element.y = x, y
    end
  end

end# Dialog
