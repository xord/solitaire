using RubySketch


class CardPlace

  include HasSprite
  include Enumerable

  extend Forwardable

  def initialize(name, linkCards: false)
    @name, @linkCards = name.intern, linkCards
    @cards = []
  end

  attr_reader :name, :cards

  def_delegators :cards, :clear, :each, :last, :empty?

  def add(*cards, updatePos: true)
    cards.map(&:to_a).flatten.each do |card|
      card.place&.pop card
      @cards.push card
      card.next  = nil
      card.pos   = posFor card if updatePos
      card.place = self
    end
    @cards.each_cons(2) {|prev, it| prev.next = @linkCards ? it : nil}
  end

  def pop(card = nil)
    return nil if @cards.empty?
    card  ||= @cards.last
    index   = @cards.index card
    poppeds =
      if index
        @cards[index..-1].tap {@cards[index..-1] = []}
      else
        [@cards.pop]
      end
    @cards.last&.next = nil
    poppeds.each_cons(2) {|prev, it| prev.next = it}
    poppeds.first.tap {|first| first.place = nil}
  end

  def id()
    @id ||= "id:#{name}"
  end

  def accept?(x, y, card)
    false
  end

  def posFor(card, index = nil)
    index ||= indexFor card
    createVector *pos.to_a(2), self.z + index + 1
  end

  def sprite()
    @sprite ||= Sprite.new(0, 0, *skin.cardSpriteSize).tap do |sp|
      sp.draw do
        noStroke
        fill 0, 20
        rect 0, 0, sp.w, sp.h, 4
      end
    end
  end

  def inspect()
    "#<CardPlace #{name}>"
  end

  private

  def indexFor(card)
    cards.index(card) || cards.size
  end

end# CardPlace


class NextsPlace < CardPlace

  def initialize(*args, **kwargs, &block)
    super
    @drawCount = 1
  end

  attr_reader :drawCount

  def add(*cards, **kwargs)
    super
    updateCards excludes: cards
  end

  def pop(*args)
    super
    updateCards
  end

  def updateCards(excludes: [])
    cards.each.with_index do |card, index|
      next if excludes.include? card
      pos = posFor card, index
      move card, pos, 0.2 if pos != card.pos
    end
  end

  def drawCount=(count)
    raise 'invalid drawCount' unless count

    @drawCount = count

    w       = skin.cardSpriteSize[0] + overlap * (count - 1)
    self.x -= w - self.w
    self.w  = w
  end

  def posFor(card, index = nil)
    index ||= indexFor card
    super.tap do |pos|
      rindex = cards.size - index
      pos.x += overlap * (drawCount - rindex).clamp(0, drawCount - 1)
    end
  end

  def overlap()
    skin.cardSpriteSize[0] * 0.4
  end

end# NextsPlace


class MarkPlace < CardPlace

  def mark()
    last&.mark
  end

  def accept?(x, y, card)
    return false if !card || card.closed? || !card.canDrop?
    hit?(x, y) &&
      card.last? &&
      card.opened? &&
      (!mark || mark == card.mark) &&
      card.number == last&.number.then {|n| n ? n + 1 : 1}
  end

end# MarkPlace


class ColumnPlace < CardPlace

  def initialize(*args, **kwargs, &block)
    super(*args, linkCards: true, **kwargs, &block)
  end

  def accept?(x, y, card)
    return false if !card || card.closed? || !card.canDrop?
    if empty?
      hit?(x, y) &&
        card.number == 13
    else
      any? {|card| card.hit?(x, y)} &&
        card.number == last.number - 1 &&
        card.color  != last.color
    end
  end

  def posFor(card, index = nil)
    index ||= indexFor card
    super.tap do |pos|
      pos.y += self.h * 0.3 * index
    end
  end

end# ColumnPlace
