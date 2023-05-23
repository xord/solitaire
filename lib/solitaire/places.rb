using RubySketch


class CardPlace

  include HasSprite
  include Enumerable

  def initialize(name, linkCards: false)
    @name, @linkCards = name.intern, linkCards
    @cards = []
  end

  attr_reader :name, :cards

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

  def clear()
    @cards.clear
  end

  def each(&block)
    @cards.each &block
  end

  def id()
    @id ||= "id:#{name}"
  end

  def empty?()
    cards.empty?
  end

  def last()
    cards.last
  end

  def accept?(x, y, card)
    false
  end

  def posFor(card, index = nil)
    index ||= indexFor card
    createVector *pos.to_a(2), self.z + index + 1
  end

  def sprite()
    @sprite ||= Sprite.new image: spriteImage
  end

  def inspect()
    "#<CardPlace #{name}>"
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

  def indexFor(card)
    cards.index(card) || cards.size
  end

end# CardPlace


class NextsPlace < CardPlace

  def initialize(*a, **k, &b)
    super
    @openCount = 1
  end

  attr_accessor :openCount

  def add(*cards, **kwargs)
    super
    updateCards excludes: cards
  end

  def updateCards(excludes: [])
    cards.each.with_index do |card, index|
      next if excludes.include? card
      pos = posFor card, index
      move card, pos, 0.2 if pos != card.pos
    end
  end

  def posFor(card, index = nil)
    index ||= indexFor card
    super.tap do |pos|
      rindex = cards.size - index
      pos.x += overlap * [openCount - rindex, 0].max
    end
  end

  def overlap()
    w * 0.4
  end

end# NextsPlace


class MarkPlace < CardPlace

  def mark()
    last&.mark
  end

  def accept?(x, y, card)
    return false if !card || card.closed? || !card.canDrop?
    hit?(x, y) &&
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
