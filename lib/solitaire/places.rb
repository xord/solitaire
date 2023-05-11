using RubySketch


class CardPlace

  include HasSprite
  include Enumerable

  def initialize()
    @card = nil
  end

  def add(card)
    card.place&.pop card
    if !@card
      @card  = card
      card.z = 1
    else
      last_      = last
      last_.next = card
      card.z     = last_.z + 1
    end
    card.place = self
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
    pos.dup
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
      card.number == last&.number.then {|n| n ? n + 1 : 1}
  end

end# MarkPlace


class ColumnPlace < CardPlace

  def accept?(x, y, card)
    if empty?
      hit?(x, y) && card.number == 13
    else
      last_ = last
      any? {|c| c.hit?(x, y)}           &&
        card.number == last_.number - 1 &&
        true#card.color  != last_.color
    end
  end

  def posFor(card)
    super.tap do |pos|
      cards = to_a
      pos.y += self.h * 0.3 * (cards.index(card) || cards.count)
    end
  end

end# ColumnPlace
