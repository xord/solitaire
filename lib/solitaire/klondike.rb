using RubySketch


class Klondike < Scene

  def initialize()
    super
    @sprites = [*cards, deck, nexts, *marks, *columns].map &:sprite
    @pick = nil
    updateLayout
    start
  end

  attr_reader :cards, :sprites

  def start()
    deck.add cards.shuffle
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

  private

  def cards()
    @cards ||= Card::MARKS.product((1..13).to_a).map {|m, n| Card.new m, n}
  end

  def deck()
    @deck ||= CardPlace.new
  end

  def nexts()
    @nexts ||= CardPlace.new
  end

  def marks()
    @marks ||= Card::MARKS.map {|mark| MarkPlace.new mark}
  end

  def columns()
    @culumns ||= 7.times.map {CardPlace.new}
  end

  def updateLayout()
    card      = cards.first
    w, h      = width, height
    cw, ch    = card.then {|c| [c.w, c.h]}
    margin    = cw * 0.2

    deck.pos  = [w - (cw + margin), margin]
    nexts.pos = [deck.x - (cw + margin), deck.y]
    marks.each do |mark|
      index    = Card::MARKS.index mark.mark
      mark.pos = [margin + (cw + margin) * index, deck.y]
    end
    columns.each.with_index do |column, index|
      s = columns.size
      m = (w - cw * s) / (s + 1) # margin
      column.pos = [m + (cw + m) * index, deck.y + deck.h + margin]
    end
  end

end# Klondike
