using RubySketch


class Klondike < Scene

  def initialize()
    super
    @places  = [deck, nexts, *marks, *columns]
    @sprites = [*cards, *places].map &:sprite
    updateLayout
    start
  end

  attr_reader :places, :sprites

  def start()
    cards.shuffle.each {|card| deck.add card.close}
    startTimer 0.5 do
      placeToColumns do
        startTimer(0.5) {openNexts}
      end
    end
  end

  def draw()
    places.each {|place| place.draw}
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
    @culumns ||= 7.times.map {ColumnPlace.new}
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

  def placeToColumns(&block)
    firstDistribution.then do |positions|
      positions.each.with_index do |(col, row), index|
        startTimer index / 50.0 do
          card = deck.pop
          card.open if col == row
          moveCard card, columns[col], 0.5 do
            block&.call if [col, row] == positions.last
          end
        end
      end
    end
  end

  def firstDistribution()
    n = columns.size
    (0...n).map { |row| (row...n).map { |col| [col, row] } }.flatten(1)
  end

  def openNexts(count = 1)
    moveCard deck.pop.open, nexts, 0.3
  end
=begin
  def refillDeck()
    @nexts.cards.shuffle!
    until @nexts.empty?
      moveCard @nexts.pop.close, @deck, 0.3
    end
  end

  def pickCard(x, y)
    draggableCards.find { _1.hit? x, y }
  end

  def draggableCards()
    [
      @columns.map { _1.cards.select &:opened? },
      @nexts.cards.last,
    ].flatten.compact.reverse
  end

  def droppablePlace(x, y, card)
    (@columns + @marks).find { _1.canAdd? x, y, card }
  end
=end

end# Klondike
