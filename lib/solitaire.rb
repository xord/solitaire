MARKS = %w[❤ ♦ ☘ ♠]

CW = 100 # card width
CH = CW * 89 / 58

class GameObject
  def initialize(width, height, z: 0, color: 255)
    @x, @y, @z = 0, 0, z
    @w, @h = width, height
    @color = color
  end

  attr_accessor :x, :y, :z, :w, :h, :color

  def pos()
    [x, y, z]
  end

  def pos=(pos)
    raise ArgumentError unless [2, 3].include?(pos.size)
    x, y, z = pos
    self.x, self.y = x, y
    self.z = z if z
  end

  def frame=(frame)
    raise ArgumentError unless frame.size == 4
    self.x, self.y, self.w, self.h = frame
  end

  def draw()
    rect 0, 0, w, h
  end

  def draw!()
    push do
      translate x, y, z
      fill *color
      noStroke
      draw
    end
  end

  def hit?(x, y)
    @x <= x && x < (@x + @w) && @y <= y && y < (@y + @h)
  end
end

class Card < GameObject
  def initialize(mark, number)
    super CW, CH
    @mark, @number, @state = mark, number, :close
    @place = @next = nil
  end

  attr_reader :mark, :number

  attr_accessor :place, :next

  def x=(x)
    old = self.x
    super
    self.next&.tap { _1.x += self.x - old }
  end

  def y=(y)
    old = self.y
    super
    self.next&.tap { _1.y += self.y - old }
  end

  def z=(z)
    old = self.z
    super
    self.next&.tap { _1.z += self.z - old }
  end

  def state=(state)
    raise ArgumentError unless [:open, :close].include?(state)
    @state = state
  end

  def open()
    @state = :open
    self
  end

  def opened?()
    @state == :open
  end

  def close()
    @state = :close
    self
  end

  def closed?()
    @state == :close
  end

  def last?
    self.next == nil && self == place&.cards.last
  end

  def each()
    card = self
    while card
      yield card
      card = card.next
    end
    self
  end

  def draw()
    opened? ? drawFace : drawBack
  end

  def red?()
    %w[❤ ♦].include? @mark
  end

  private

  NUM_SYMBOLS = { 11 => :J, 12 => :Q, 13 => :K }

  def drawFace()
    @face ||= createGraphics(w, h).tap do |g|
      g.beginDraw do
        drawBackground g, 255, 0
        g.fill(*(red? ? [255, 0, 0] : 0))
        g.textAlign CENTER, CENTER
        s = @w / 2
        g.textSize 40
        g.text @mark, 2, 0, s, s
        g.text NUM_SYMBOLS[@number] || @number, s - 2, 0, s, s
        g.textSize 60
        g.text @mark, 0, s, @w, @h - s
      end
    end
    image @face, 0, 0
  end

  def drawBack()
    drawBackground self, [200, 100, 100], 200
  end

  def drawBackground(g, color, strokeColor)
    g.fill *color
    g.stroke *strokeColor
    g.strokeWeight 2
    g.rect 0, 0, @w, @h, @w / 10
  end
end

class CardPlace < GameObject
  def initialize()
    super CW, CH, z: -1, color: [40, 120, 40]
    @cards = []
  end

  attr_reader :cards

  def add(*cards)
    cards.flatten.each do |card|
      while card
        placeCard card, @cards.size
        @cards.push card
        card.place = self
        card = card.next
      end
    end
  end

  def pop(card = nil)
    if card
      index = @cards.index(card) || return
      @cards.slice! index, @cards.size
      card.each { _1.place = nil }
      card
    else
      @cards.pop.tap { _1.place = nil }
    end
  ensure
    @cards.last&.next = nil
  end

  def empty?()
    @cards.empty?
  end

  def draw()
    rect 0, 0, w, h, w / 10
  end

  private

  def placeCard(card, index)
    card.pos = pos
    card.z += index
  end
end

class ColumnPlace < CardPlace
  def canAdd?(x, y, card)
    if empty?
      hit?(x, y) && card.number == 13
    else
      cards.last.then do
        _1.hit?(x, y) &&
          _1.number == card.number + 1 &&
          _1.red? != card.red?
      end
    end
  end

  def add(*cards)
    super
    @cards.each_cons 2 do |card, next_|
      card.next = next_
      next_.next = nil
    end
  end

  private

  def placeCard(card, index)
    super
    card.y += w / 2 * index
  end
end

class MarkPlace < CardPlace
  def initialize(mark)
    super()
    @mark = mark
  end

  attr_reader :mark

  def canAdd?(x, y, card)
    hit?(x, y) &&
      card.mark == mark &&
      card.number == cards.last&.number.then { _1 ? _1 + 1 : 1 }
  end

  def draw()
    super
    fill *color.map { _1 - 10 }
    textSize 50
    textAlign CENTER, CENTER
    text mark, 0, 0, w, h
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

def now()
  Time.now.to_f
end

def unique()
  Object.new.object_id
end

def startTimer(name = unique, seconds, &block)
  $timers[name] = [now + seconds, block]
end

def stopTimer(name)
  $timers.delete name
end

def getTimer(name)
  $timers[name]
end

def fireTimers()
  now_ = now
  blocks = []
  $timers.delete_if do |_, (time, block)|
    (now_ >= time).tap { blocks.push block if _1 }
  end
  blocks.each { _1.call }
end

OUT_EXPO = lambda { |x| 1.0 - 2 ** (-10 * x.clamp(0.0, 1.0)) }

def animate(name = unique, seconds, ease: OUT_EXPO, &block)
  start = now
  eachDrawBlock = lambda do
    t = (now - start) / seconds
    if t >= 1.0
      block.call ease.call(1.0), true
    else
      block.call ease.call(t), false
      startTimer name, 0, &eachDrawBlock
    end
  end
  startTimer name, 0, &eachDrawBlock
end

def move(obj, toPos, seconds, zOnMove: nil, &block)
  from = createVector obj.x, obj.y, obj.z
  to = createVector *toPos
  animate seconds do |t, finished|
    obj.pos = Vector.lerp(from, to, t).then { [_1.x, _1.y, _1.z] }
    obj.z = zOnMove if zOnMove && !finished
    block&.call if finished
  end
end

def moveCard(card, toPlace, seconds, zOnMove: nil, &block)
  fromPos = card.pos
  toPlace.add card
  toPos = card.pos.dup
  card.pos = fromPos
  move card, toPos, seconds, zOnMove: zOnMove, &block
end

setup do
  size 800, 1200
  $clickCount = $clickPrevTime = 0
  $timers = {}
  $game = Game.new
end

draw do
  fireTimers
  push { $game.draw }
end

mouseClicked do
  $clickCount = (now - $clickPrevTime) < 0.3 ? $clickCount + 1 : 1
  $clickPrevTime = now
  $game.mouseClicked mouseX, mouseY, $clickCount
end

mousePressed do
  $game.mousePressed mouseX, mouseY
end

mouseReleased do
  $game.mouseReleased mouseX, mouseY
end

mouseDragged do
  $game.mouseDragged mouseX, mouseY, pmouseX, pmouseY
end
