using RubySketch


def drawSprite(*args)
  sprite *args
end


class CardPlace

  include HasSprite

  def initialize()
    @cards = []
  end

  attr_reader :cards

  def add(*cards)
    cards.flatten.each do |card|
      @cards.push card
      card.instance_variable_set :@place, self
      card.pos = pos
      card.close
    end
  end

  def remove(*cards)
    cards.flatten!
    @cards -= cards
    cards.each do |card|
      card.instance_variable_set :@place, nil
    end
  end

  def draw()
    drawSprite self.sprite
    cards.each {|card| drawSprite card.sprite}
  end

  def sprite()
    @sprite ||= Sprite.new image: spriteImage
  end

  private

  def spriteImage()
    @image ||= createGraphics(CW, CH).tap do |g|
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
    super
    @mark = mark
  end

  attr_reader :mark

end# MarkPlace


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
