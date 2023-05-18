using RubySketch


class Card

  include HasSprite
  include Enumerable

  MARKS = %i[heart diamond clover spade]

  def initialize(game, mark, number)
    @game, @mark, @number, @state, @open = game, mark, number, :close, 0
    @place = @next = nil
  end

  attr_reader :mark, :number, :place

  attr_accessor :next

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

  def addTo(place, seconds = 0, hover: true, **kwargs, &block)
    pos    = place.posFor self
    self.z = pos.z + (hover ? 100 : 0)
    place.add self, updatePos: false
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
    self.pos = createVector x, self.y, self.z
    self.x
  end

  def y=(y)
    self.pos = createVector self.x, y, self.z
    self.y
  end

  def z=(z)
    self.pos = createVector self.x, self.y, z
    self.z
  end

  def open(sec = 0.3)
    @state = :open
    animate(sec) {|t| @open = 180 * t}
    self
  end

  def opened?()
    @state == :open
  end

  def close(sec = 0)
    @state = :close
    animate(sec) {|t| @open = 180 * (1.0 - t)}
    self
  end

  def closed?()
    @state == :close
  end

  def color()
    MARKS[0, 2].include?(mark) ? :red : :black
  end

  def count()
    reduce(0) {|n| n + 1}
  end

  def last?()
    self.next == nil
  end

  def sprite()
    @sprite ||= Sprite.new(0, 0, *spriteSize, image: closedImage).tap do |sp|
      sp.pivot = [rand, rand]
      sp.angle = rand -10.0..10.0
      sp.update do
        sp.image = @open > 90 ? openedImage : closedImage
      end
      sp.draw do |&draw|
        push do
          blendMode SUBTRACT
          tint 100
          translate 2, 5
          draw.call
        end
        translate  sp.w / 2,  sp.h / 2
        rotate @open
        translate -sp.w / 2, -sp.h / 2
        draw.call
      end
      sp.mousePressed do
        mousePressed sp.mouseX, sp.mouseY
      end
      sp.mouseReleased do |clickCount|
        mouseReleased sp.mouseX, sp.mouseY, clickCount
      end
      sp.mouseDragged do
        x, y = sp.mouseX, sp.mouseY
        mouseDragged x, y, x - sp.pmouseX, y - sp.pmouseY
      end
      sp.mouseClicked do
        @game.cardClicked self
      end
    end
  end

  def inspect()
    "#<Card #{mark} #{number}>"
  end

  private

  def mousePressed(x, y)
    @prevPlace = place
    @startPos  = createVector x, y, self.z
    self.z    += 100
  end

  def mouseReleased(x, y, clickCount)
    self.z = @startPos.z if @startPos
    pos    = sprite.to_screen createVector x, y
    @game.cardDropped pos.x, pos.y, self, @prevPlace if
      @prevPlace && clickCount == 0
  end

  def mouseDragged(x, y, dx, dy)
    self.pos += createVector x - @startPos.x, y - @startPos.y if @startPos
  end

  def spriteSize()
    self.class.spriteSize
  end

  def openedImage()
    @openedImage ||= createGraphics(*self.class.spriteSize).tap do |g|
      cw, ch = self.class.eachCardSize
      x      = ([nil] + (2..13).to_a + [1])  .index(number) * cw
      y      = %i[heart clover diamond spade].index(mark)   * ch
      g.beginDraw
      g.copy self.class.cardsImage, x, y, cw, ch, 0, 0, g.width, g.height
      g.endDraw
    end
  end

  def closedImage()
    self.class.closedImage
  end

  def self.spriteSize()
    cw, ch, margin, ncolumns = *eachCardSize, 4, 7
    spriteWidth = (width - margin * (ncolumns + 1)) / ncolumns
    @size ||= [spriteWidth, spriteWidth * (ch.to_f / cw)].map &:to_i
  end

  def self.eachCardSize()
    [35, 47]
  end

  def self.closedImage()
    cw, ch = eachCardSize
    @closedImage ||= createGraphics(*spriteSize).tap do |g|
      g.beginDraw
      g.copy cardsImage, 0, ch, cw, ch, 0, 0, g.width, g.height
      g.endDraw
    end
  end

  def self.cardsImage()
    @cardsImage ||= loadImage 'data/cards.png'
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
