using RubySketch


class Game
  def initialize()
    @background = GameObject.new 0, 0, z: -3, color: [50, 140, 50]
    @upper = GameObject.new 0, 0, z: -2, color: [50, 130, 50]
    @deck = CardPlace.new
    @nexts = CardPlace.new
    @marks = MARKS.map { MarkPlace.new _1 }
    @columns = (1..7).map { ColumnPlace.new }
    @cards = MARKS.product((1..13).to_a)
      .map { |mark, number| Card.new mark, number }
    @all = [@background, @upper, @deck, @nexts, *@marks, *@columns, *@cards]
    updateFrames
    start
  end

  def updateFrames()
    w, h, margin = width, height, CW * 0.2
    @background.frame = [0, 0, w, h]
    @upper.frame = [0, 0, w, CH + margin * 2]
    @deck.pos = [w - (CW + margin), (@upper.h - @deck.h) / 2]
    @nexts.pos = [@deck.x - (CW + margin), @deck.y]
    @marks.each do |mark|
      mark.pos = [margin + (CW + margin) * MARKS.index(mark.mark), @deck.y]
    end
    @columns.each.with_index do |column, index|
      s = @columns.size
      m = (width - CW * s) / (s + 1) # margin
      column.pos = [m + (CW + m) * index, @upper.y + @upper.h + margin]
    end
  end

  def start()
    @deck.add @cards.shuffle
    startTimer 0.5 do
      placeToColumns do
        startTimer(0.5) { openNexts }
      end
    end
  end

  def draw()
    @all.each do |o|
      push { o.draw! }
    end
    if @marks.all? { _1.cards.size == 13 }
      fill 255
      textSize 100
      textAlign CENTER, CENTER
      text "CLEAR!", 0, 0, width, height
    end
  end

  def mouseClicked(x, y, clickCount)
    card = pickCard x, y
    if card && card.last? && clickCount == 2
      @marks.find { _1.canAdd? _1.x, _1.y, card }&.then do |mark|
        card.place.pop card
        moveCard card, mark, 0.3
      end
    elsif @deck.hit? x, y
      if @deck.empty?
        refillDeck
      else
        openNexts
      end
    elsif @nexts.hit? x, y
      openNexts if @nexts.empty?
    else
      @columns.each do |column|
        column.cards.last&.then { _1.open if _1.hit? x, y }
      end
    end
  end

  def mousePressed(x, y)
    draggableCards.find { _1.hit? x, y }&.then do |card|
      @drag = Drag.new card
      @drag.start
    end
  end

  def mouseReleased(x, y)
    return unless @drag
    droppablePlace(x, y, @drag.card).then do |place|
      if place
        @drag.drop place
      else
        @drag.cancel
      end
    end
    @drag = nil
  end

  def mouseDragged(x, y, prevX, prevY)
    @drag&.drag x - prevX, y - prevY
  end

  private

  def placeToColumns(&block)
    firstDistribution.then do |positions|
      positions.each.with_index do |(col, row), index|
        startTimer index / 50.0 do
          card = @deck.pop
          card.open if col == row
          moveCard card, @columns[col], 0.5 do
            block&.call if [col, row] == positions.last
          end
        end
      end
    end
  end

  def firstDistribution()
    n = @columns.size
    (0...n).map { |row| (row...n).map { |col| [col, row] } }.flatten(1)
  end

  def openNexts(count = 1)
    moveCard @deck.pop.open, @nexts, 0.3, zOnMove: 100
  end

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
end


class Drag
  def initialize(card)
    @card = card
  end

  attr_reader :card

  def start(z: 100)
    @startPos = card.pos.dup
    card.z = z if z
  end

  def drag(dx, dy)
    card&.then do
      _1.x += dx
      _1.y += dy
    end
  end

  def drop(place)
    card.place.pop card
    moveCard card, place, 0.3
  end

  def cancel()
    move card, @startPos, 0.3
  end
end
