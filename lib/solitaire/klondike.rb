using RubySketch


class Klondike < Scene

  def initialize()
    super
    @sprites = [*cards, *places].map &:sprite
    updateLayout
    start
  end

  attr_reader :sprites

  def start()
    cards.shuffle.each {|card| card.addTo deck}
    startTimer 0.5 do
      placeToColumns do
        startTimer(0.5) {openNexts}
      end
    end
  end

  def draw()
    (@places - columns).each {|place| place.draw}
    (0..).each do |index|
      break unless columns.map {|column| column.drawAt index}.any?
    end
    @picked&.each {|card| card.draw}
  end

  def picked(card)
    @picked = card if card.z >= (@picked&.z || 0)
  end

  def mouseReleased(x, y, mouseButton)
    place = getPlaceAccepts(x, y, @picked) || @placePickedFrom
    @picked&.addTo place, 0.2 if place
    @picked = @placePickedFrom = nil
  end

  def mouseDragged(x, y, dx, dy)
    return unless @picked
    unless @placePickedFrom
      @placePickedFrom = @picked.place
      @placePickedFrom.pop @picked
    end
    @picked.pos += createVector(dx, dy)
  end

  def deckClicked()
    deck.cards.empty? ? refillDeck : openNexts
  end

  def nextsClicked()
    openNexts if nexts.cards.empty?
  end

  def cardClicked(card)
    card.open if
      card.closed? &&
      card.place&.is_a?(ColumnPlace) &&
      card == card.place&.cards.last
  end

  private

  def places()
    @places ||= [deck, nexts, *marks, *columns]
  end

  def cards()
    @cards ||= Card::MARKS
      .product((1..13).to_a)
      .map {|m, n| Card.new self, m, n}
      .each {|card| card.sprite.mouseClicked {cardClicked card}}
  end

  def deck()
    @deck ||= CardPlace.new.tap do |deck|
      deck.sprite.mouseClicked {deckClicked}
    end
  end

  def nexts()
    @nexts ||= CardPlace.new.tap do |nexts|
      nexts.sprite.mouseClicked {nextsClicked}
    end
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
          card.addTo columns[col], 0.5 do
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
    deck.pop.open.addTo nexts, 0.3
  end

  def refillDeck()
    nexts.pop.close.addTo deck, 0.3 until nexts.cards.empty?
  end

  def getPlaceAccepts(x, y, card)
    return nil unless card
    (columns + marks).find {|place| place.accept? x, y, card}
  end

end# Klondike
