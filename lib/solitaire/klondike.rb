using RubySketch


class Klondike < Scene

  def initialize()
    super
    @sprites = [*cards, *places].map &:sprite
    updateLayout
    start
  end

  def sprites()
    @sprites + particle.sprites
  end

  def start()
    cards.shuffle.each {|card| card.addTo deck}
    startTimer 0.5 do
      placeToColumns do
        startTimer(0.5) {openNexts}
      end
    end
  end

  def draw()
    places.each {|place| sprite place.sprite}
    cards
      .sort {|a, b| a.drawPriority <=> b.drawPriority}
      .each {|card| sprite card.sprite}
    particle.draw
  end

  def picked(card)
    @picked = card if card.z >= (@picked&.z || 0)
  end

  def mousePressed(x, y, mouseButton, clickCount)
    if clickCount == 2
      cards
        .select {|card| card.hit? x, y}
        .sort {|a, b| a.drawPriority <=> b.drawPriority}
        .last&.then {|card| cardDoubleClicked card}
    end
  end

  def mouseReleased(x, y, mouseButton)
    card = @picked
    if place = getPlaceAccepts(x, y, card)
      card.addTo place, 0.2
    elsif card && @placePickedFrom
      prevPos = card.pos
      card.addTo @placePickedFrom, 0.2, ease: :quadIn do |t, finished|
        backToPlace card, prevPos if finished
        prevPos = card.pos.dup
      end
    end
    @picked = @placePickedFrom = nil
  end

  def mouseDragged(x, y, dx, dy)
    return unless @picked
    unless @placePickedFrom
      @placePickedFrom = @picked.place
      @placePickedFrom.pop @picked
    end
    @picked.z    = 100
    @picked.pos += createVector(dx, dy)
  end

  def deckClicked()
    deck.empty? ? refillDeck : openNexts
  end

  def nextsClicked()
    openNexts if nexts.empty?
  end

  def cardClicked(card)
    card.open if
      card.closed? &&
      card.place&.is_a?(ColumnPlace) &&
      card.last?
  end

  def cardDoubleClicked(card)
    mark = marks.find {|place| place.accept? place.x, place.y, card}
    card.addTo mark, 0.3 if mark
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

  def particle()
    @particle ||= Particle.new
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
          card.addTo columns[col], 0.5 do |t, finished|
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
    shake vector: vel * 0.1 * card.count
    32.times {
      x, y, w, h = randomEdge card
      pos        = createVector x, y
      vec        = (pos - card.center).normalize * vel.mag
      emitParticle pos, w, h, vec
    }
  end

  def emitParticle(pos, w, h, vec)
    par   = particle.new pos.x, pos.y, w, h
    toPos = pos + vec * rand(0.5...1.0)
    sec   = [vec.mag / 10, 2].min
    move par, toPos, sec do |t, finished|
      par.alpha = (1.0 - t) * 255
      par.delete if finished
    end
  end

  def randomEdge(card)
    if rand < card.w / (card.w + card.h)
      [
        card.x + rand(card.w),
        card.y + (rand < 0.5 ? 0 : card.h),
        rand(3.0..5.0),
        2
      ]
    else
      [
        card.x + (rand < 0.5 ? 0 : card.w),
        card.y + rand(card.h),
        2,
        rand(3.0..5.0)
      ]
    end
  end

  def randomEdge2(card)
    (cw, ch), v        = card.size.to_a, Vector.random2D
    cardGrad, vecGrad  = ch / cw, v.y / v.x
    edgePos =
      if 0 <= v.x
        if   cardGrad <  vecGrad  then [0, 0]#[cw / 2 + ch / 2 / vecGrad, 0]
        elsif vecGrad < -cardGrad then [0, 0]#[cw / 2 - ch / 2 / vecGrad, ch]
        else                           [cw, ch / 2 + cw / 2 * vecGrad]
        end
      else
        if   cardGrad <  vecGrad  then [0, 0]#[cw / 2 - ch / 2 / vecGrad, ch]
        elsif vecGrad < -cardGrad then [0, 0]#[cw / 2 + ch / 2 / vecGrad, 0]
        else                           [0, ch / 2 + -cw / 2 * vecGrad]
        end
      end
    card.pos + edgePos
  end

end# Klondike
