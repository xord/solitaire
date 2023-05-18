using RubySketch


class Klondike < Scene

  def initialize()
    super
    @sprites = [*cards, *places].map &:sprite
    updateLayout
    start
  end

  def sprites()
    super + @sprites
  end

  def start()
    deck.add *cards.shuffle
    startTimer 0.5 do
      placeToColumns do
        startTimer(0.5) {openNexts}
      end
    end
  end

  def draw()
    places.each {|place| sprite place.sprite}
    cards
      .sort {|a, b| a.z <=> b.z}
      .each {|card| sprite card.sprite}
    blendMode ADD
    particle.draw
  end

  def cardClicked(card)
    case place = card.place
    when deck     then deckClicked
    when nexts    then nextsClicked
    when *columns then card.closed? ? closedCardClicked(card) : openedCardClicked(card)
    end
  end

  def deckClicked()
    deck.empty? ? refillDeck : openNexts
  end

  def nextsClicked()
    openNexts if nexts.empty?
  end

  def closedCardClicked(card)
    card.open if card.last?
  end

  def openedCardClicked(card)
    mark = marks.find {|place| place.accept? place.x, place.y, card}
    card.addTo mark, 0.3 if mark
  end

  def cardDropped(x, y, card, prevPlace)
    if place = getPlaceAccepts(x, y, card)
      card.addTo place, 0.2
    elsif prevPlace
      prevPos = card.pos
      card.addTo prevPlace, 0.15, ease: :quadIn do |t, finished|
        backToPlace card, prevPos if finished
        prevPos = card.pos.dup
      end
    end
  end

  private

  def places()
    @places ||= [deck, nexts, *marks, *columns]
  end

  def cards()
    @cards ||= Card::MARKS.product((1..13).to_a)
      .map {|m, n| Card.new self, m, n}
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
          card.addTo columns[col], 0.5, hover: false do |t, finished|
            block&.call if finished && [col, row] == positions.last
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
    deck.pop.open.addTo nexts, 0.3 unless deck.empty?
  end

  def refillDeck()
    nexts.pop.close.addTo deck, 0.3 until nexts.empty?
  end

  def getPlaceAccepts(x, y, card)
    return nil unless card
    (columns + marks).find {|place| place.accept? x, y, card}
  end

  def backToPlace(card, prevPos)
    vel = card.pos - prevPos
    return if vel.mag < 3
    shake vector: vel / 10 * card.count
    10.times {
      x, y = randomEdge card
      size = rand(2.0..10.0)
      pos  = createVector x, y
      vec  = (pos - card.center).normalize * 10
      sec  = 0.5
      par  = emitParticle x, y, size, size, sec
      animate sec do |t|
        par.pos   = pos + vec * t
        par.alpha = (1.0 - t) * 255
      end
    }
  end

  def randomEdge(card)
    if rand < card.w / (card.w + card.h)
      [
        card.x + rand(card.w),
        card.y + (rand < 0.5 ? 0 : card.h)
      ]
    else
      [
        card.x + (rand < 0.5 ? 0 : card.w),
        card.y + rand(card.h)
      ]
    end
  end

end# Klondike
