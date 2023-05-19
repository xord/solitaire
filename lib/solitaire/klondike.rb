using RubySketch


class Klondike < Scene

  def initialize()
    super
    @sprites = [*cards, *places].map &:sprite
    updateLayout
    start
  end

  def sprites()
    super + @sprites + buttons
  end

  def start()
    history.disable
    deck.add *cards.shuffle
    startTimer 0.5 do
      placeToColumns do
        startTimer 0.5 do
          openNexts
          history.enable
        end
      end
    end
  end

  def draw()
    sprite *places.map(&:sprite)
    sprite *cards.sort {|a, b| a.z <=> b.z}.map(&:sprite)
    sprite *buttons

    blendMode ADD
    particle.draw
  end

  def cardClicked(card)
    if newPlace = getPlaceToGo(card)
      moveCard card, newPlace, 0.3
    else
      case card.place
      when deck     then deckClicked
      when nexts    then nextsClicked
      when *columns then openCard card if card.closed? && card.last?
      end
    end
  end

  def deckClicked()
    deck.empty? ? refillDeck : openNexts
  end

  def nextsClicked()
    openNexts if nexts.empty?
  end

  def cardDropped(x, y, card, prevPlace)
    if place = getPlaceAccepts(x, y, card)
      moveCard card, place, 0.2
    elsif prevPlace
      prevPos = card.pos
      history.disable do
        moveCard card, prevPlace, 0.15, ease: :quadIn do |t, finished|
          backToPlace card, prevPos if finished
          prevPos = card.pos.dup
        end
      end
    end
  end

  def inspect()
    "#<Klondike:#{object_id}>"
  end

  private

  def history()
    @history ||= History.new
  end

  def cards()
    @cards ||= Card::MARKS.product((1..13).to_a)
      .map {|m, n| Card.new self, m, n}
      .each {|card| card.sprite.mouseClicked {cardClicked card}}
  end

  def places()
    @places ||= [deck, nexts, *marks, *columns]
  end

  def deck()
    @deck ||= CardPlace.new(:deck).tap do |deck|
      deck.sprite.mouseClicked {deckClicked}
    end
  end

  def nexts()
    @nexts ||= CardPlace.new(:nexts).tap do |nexts|
      nexts.sprite.mouseClicked {nextsClicked}
    end
  end

  def marks()
    @marks ||= Card::MARKS.map {|mark| MarkPlace.new "mark_#{mark}", mark}
  end

  def columns()
    @culumns ||= 7.times.map.with_index {|i| ColumnPlace.new "column_#{i + 1}"}
  end

  def buttons()
    [undoButton, redoButton, restartButton, debugButton]
  end

  def undoButton()
    @undoButton ||= Button.new(:UNDO, [120, 140, 160], 1.5).tap do |b|
      b.update  {b.enable history.canUndo?}
      b.clicked {history.undo {|action| undo action}}
    end
  end

  def redoButton()
    @redoButton ||= Button.new(:REDO, [160, 140, 120], 1.5).tap do |b|
      b.update  {b.enable history.canRedo?}
      b.clicked {history.redo {|action| self.redo action}}
    end
  end

  def restartButton()
    @restartButton ||= Button.new(:RESTART, [140, 160, 120], 2).tap do |b|
      b.clicked {startTimer(0) {transition self.class.new}}
    end
  end

  def debugButton()
    @debugButton ||= Button.new(:DEBUG, [100, 100, 100], 2).tap do |b|
      b.clicked {save}
    end
  end

  def updateLayout()
    card      = cards.first
    y, w, h   = 0, width, height
    cw, ch    = card.then {|c| [c.w, c.h]}
    margin    = cw * 0.2

    y = margin
    undoButton   .pos = [margin, y]
    redoButton   .pos = [undoButton.x + undoButton.w + margin, y]
    restartButton.pos = [width - (restartButton.w + margin), y]

    y = undoButton.y + undoButton.h + margin

    deck.pos  = [w - (cw + margin), y]
    nexts.pos = [deck.x - (cw + margin), deck.y]
    marks.each do |mark|
      index    = Card::MARKS.index mark.mark
      mark.pos = [margin + (cw + margin) * index, deck.y]
    end

    y = deck.y + deck.h + margin

    columns.each.with_index do |column, index|
      s = columns.size
      m = (w - cw * s) / (s + 1) # margin
      column.pos = [m + (cw + m) * index, y]
    end

    debugButton.pos = [margin, height - (debugButton.h + margin)]
  end

  def placeToColumns(&block)
    firstDistribution.then do |positions|
      positions.each.with_index do |(col, row), index|
        startTimer index / 50.0 do
          card = deck.last
          openCard card if col == row
          moveCard card, columns[col], 0.5, hover: false do |t, finished|
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

  def openCard(card)
    return if card.opened?
    card.open
    history.push [:open, card]
  end

  def closeCard(card)
    return if card.closed?
    card.close
    history.push [:close, card]
  end

  def moveCard(
    card, toPlace, seconds = 0, from: card.place, hover: true,
    **kwargs, &block)

    card.place&.pop card if card.place

    pos    = toPlace.posFor card
    card.z = pos.z + (hover ? 100 : 0)
    toPlace.add card, updatePos: false
    move card, pos, seconds, **kwargs, &block

    history.push [:move, card, from, toPlace]
  end

  def openNexts(count = 1)
    return if deck.empty?
    history.record do
      card = deck.last
      openCard card
      moveCard card, nexts, 0.3
    end
  end

  def refillDeck()
    history.record do
      until nexts.empty?
        card = nexts.last
        closeCard card
        moveCard card, deck, 0.3
      end
    end
  end

  def getPlaceAccepts(x, y, card)
    (columns + marks).find {|place| place.accept? x, y, card}
  end

  def getPlaceToGo(card)
    marks.find {|place| place.accept? *place.center.to_a(2), card} ||
      columns.shuffle.find {|place| place.accept? *place.center.to_a(2), card}
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

  def undo(action)
    history.disable do
      case action
      in [:open,  card]           then closeCard card
      in [:close, card]           then  openCard card
      in [:move,  card, from, to] then moveCard card, from, 0.2, from: to
      end
    end
  end

  def redo(action)
    history.disable do
      case action
      in [:open,  card]           then  openCard card
      in [:close, card]           then closeCard card
      in [:move,  card, from, to] then moveCard card, to, 0.2, from: from
      end
    end
  end

end# Klondike
