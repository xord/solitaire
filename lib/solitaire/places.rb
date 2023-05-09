using RubySketch


class CardPlace

  include HasSprite

  def initialize()
    @cards = []
  end

  attr_reader :cards

  def add(*cards)
    cards.flatten.each do |card|
      card.each do |c|
        @cards.push c
        c.place = self
        c.next  = nil
        c.z     = @cards.size
      end
    end
  end

  def pop(card = nil)
    if card
      index = @cards.index(card) || return
      cards = @cards.slice! index, @cards.size
      cards.each_cons(2) {|card, next_| card.next = next_}
      cards.first
    else
      @cards.pop
    end.tap do |card|
      card&.each {|c| c.place = nil}
      @cards.last&.next = nil
    end
  end

  def accept?(x, y, card)
    false
  end

  def posFor(card)
    pos.dup
  end

  def draw(index = nil)
    drawSprite sprite
    @cards.each {|card| card.draw}
  end

  def sprite()
    @sprite ||= Sprite.new image: spriteImage
  end

  private

  def spriteImage()
    @spriteImage ||= createGraphics(CW, CH).tap do |g|
      g.beginDraw
      g.noStroke
      g.fill 100, 32
      g.rect 0, 0, g.width, g.height, 4
      g.endDraw
    end
  end

end# CardPlace


class MarkPlace < CardPlace

  def initialize(mark)
    super()
    @mark = mark
  end

  attr_reader :mark

  def accept?(x, y, card)
    hit?(x, y) &&
      card.mark   == mark &&
      card.number == @cards.last&.number.then {|n| n ? n + 1 : 1}
  end

end# MarkPlace


class ColumnPlace < CardPlace

  def accept?(x, y, card)
    if @cards.empty?
      hit?(x, y) && card.number == 13
    else
      last = @cards.last
      @cards.any? {|c| c.hit?(x, y)}   &&
        card.number == last.number - 1 &&
        card.color  != last.color
    end
  end

  def posFor(card)
    super.tap do |pos|
      pos.y += self.h * 0.3 * (@cards.index(card) || @cards.size)
    end
  end

  def drawAt(index)
    drawSprite sprite if index == 0
    @cards[index]&.tap {|card| drawSprite card.sprite}
  end

end# ColumnPlace


class CardPlaceOld < GameObject
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

class ColumnPlaceOld < CardPlace
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

class MarkPlaceOld < CardPlace
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
