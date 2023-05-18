using RubySketch


class CardPlace

  include HasSprite
  include Enumerable

  def initialize()
    @card = nil
  end

  def add(*cards, updatePos: true)
    cards.flatten.each do |card|
      card.place&.pop card
      card.pos = posFor card if updatePos
      unless @card
        @card     = card
      else
        last.next = card
      end
      card.place = self
    end
  end

  def pop(card = nil)
    return nil unless @card
    if card ? @card == card : @card.last?
      it    = @card
      @card = nil
      return it
    else
      each_cons 2 do |prev, it|
        if card ? it == card : it.last?
          prev.next = nil
          return it
        end
      end
    end
    nil
  end

  def each(&block)
    card = @card
    while card
      next_ = card.next
      block.call card
      card  = next_
    end
    self
  end

  def empty?()
    @card == nil
  end

  def last()
    c = @card
    c = c.next while c&.next
    c
  end

  def accept?(x, y, card)
    false
  end

  def posFor(card)
    x, y = pos.to_a
    createVector x, y, (last&.z || 0) + 1
  end

  def sprite()
    @sprite ||= Sprite.new image: spriteImage
  end

  private

  def spriteImage()
    @spriteImage ||= createGraphics(*Card.spriteSize).tap do |g|
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
      card.opened? &&
      card.mark   == mark &&
      card.number == last&.number.then {|n| n ? n + 1 : 1}
  end

end# MarkPlace


class ColumnPlace < CardPlace

  def accept?(x, y, card)
    return false if card.closed?
    if empty?
      hit?(x, y) &&
        card.number == 13
    else
      any? {|card| card.hit?(x, y)} &&
        card.number == last.number - 1 &&
        card.color  != last.color
    end
  end

  def posFor(card)
    super.tap do |pos|
      cards = to_a
      pos.y += self.h * 0.3 * (cards.index(card) || cards.count)
    end
  end

end# ColumnPlace
