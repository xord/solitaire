using RubySketch


class Klondike < Scene

  def initialize()
    super
    @cards   = Card::MARKS.product((1..13).to_a).map {|m, n| Card.new m, n}
    @sprites = cards.map &:sprite
    @pick    = nil
    shuffle
  end

  attr_reader :cards, :sprites

  def shuffle()
    cards.each do |card|
      sp         = card.sprite
      sp.x       = rand 0...(windowWidth  - sp.width)
      sp.y       = rand 0...(windowHeight - sp.height)
      sp.angle   = rand 0...360
      sp.dynamic = true
      sp.mousePressed  {@pick = sp}
      sp.mouseReleased {@pick = nil}
      sp.contact? {true}
    end
  end

  def draw()
    sprite @sprites
  end

  def mousePressed(x, y, button, clickCount)
  end

  def mouseReleased(x, y, button)
  end

  def mouseMoved(x, y, dx, dy)
  end

  def mouseDragged(x, y, dx, dy)
    @pick&.x += dx
    @pick&.y += dy
  end

end# Klondike
