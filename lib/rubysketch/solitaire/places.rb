using RubySketch


class CardPlace

  include HasSprite
  include Enumerable

  extend Forwardable

  def initialize(game, name, linkCards: false)
    @game, @name, @linkCards = game, name.intern, linkCards
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
        fill *skin.translucentBackgroundColor
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
