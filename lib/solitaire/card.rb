using RubySketch


class Card

  include HasSprite
  include Enumerable

  MARKS = %i[heart diamond clover spade]

  def initialize(game, mark, number)
    @game, @mark, @number, @state, @z = game, mark, number, :close, 0
    @place = @next = nil
  end

  attr_reader :mark, :number, :place

  attr_accessor :next, :z

  def each(&block)
    return to_enum :each unless block
    card = self
    while card
      next_ = card.next
      block.call card
      card = next_
    end
    self
  end

  def addTo(place, seconds = 0, **kwargs, &block)
    pos = place.posFor self
    place.add self
    move self, pos, seconds, **kwargs, &block
  end

  def place=(place)
    @place           = place
    self.next&.place = place
  end

  def pos=(pos)
    old = self.pos.dup
    super
    self.next&.pos += self.pos - old
    self.pos
  end

  def x=(x)
    self.pos = createVector(x, self.y)
    self.x
  end

  def y=(y)
    self.pos = createVector(self.x, y)
    self.y
  end

  def z=(z)
    old, @z       = self.z, z
    self.next&.z += @z - old
    self.z
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

  def color()
    MARKS[0, 2].include?(mark) ? :red : :black
  end

  def size()
    reduce(0) {|n| n + 1}
  end

  def last?()
    self.next == nil
  end

  def drawPriority()
    z + (pos != @prevPos ? 100 : 0)
  end

  def sprite()
    @sprite ||= Sprite.new(image: closedImage).tap do |sp|
      sp.pivot = [0.5, 0.5]
      sp.angle = rand -2.0..2.0
      sp.update do
        sp.image = opened? ? openedImage : closedImage
        @prevPos = sp.pos
      end
      sp.mousePressed do
        @game.picked self if opened?
      end
    end
  end

  def inspect()
    "#<Card #{mark} #{number}>"
  end

  private

  def openedImage()
    @openedImage ||= createGraphics(CW, CH).tap do |g|
      c         = self.class
      s         = c.marksImage.height # size
      m         = 4 # margin
      markIndex = Card::MARKS.index self.mark
      number    = (self.number - 1)
      g.beginDraw
      g.image c.cardImage, 0, 0
      g.copy c.marksImage, markIndex * s, 0, s, s,               m, m, s, s
      g.copy c.numbersImage,  number * s, 0, s, s, g.width - s - m, m, s, s
      g.endDraw
    end
  end

  def closedImage()
    self.class.closedImage
  end

  def self.closedImage()
    @closedImage ||= createGraphics(CW, CH).tap do |g|
      g.beginDraw
      g.copy cardImage, CW, 0, CW, CH, 0, 0, CW, CH
      g.endDraw
    end
  end

  def self.cardImage()
    @cardImage ||= loadImage 'data/card.png'
  end

  def self.marksImage()
    @marksImage ||= loadImage 'data/marks.png'
  end

  def self.numbersImage()
    @numbersImage ||= loadImage 'data/numbers.png'
  end

  def __find_or_last_and_prev(card = nil)
    prev, it = nil, self
    while it.next
      break if it == card
      prev, it = it, it.next
    end
    return it, prev
  end

end# Card
