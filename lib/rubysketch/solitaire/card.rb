using RubySketch


class Card

  include HasSprite
  include Enumerable
  include Comparable

  MARKS = %i[heart diamond clover spade]

  def initialize(game, mark, number)
    @game, @mark, @number = game, mark, number
    @state, @open         = :close, 0
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

  def hover(rise = 100, base: self.z)
    self.z = base + rise
  end

  def name()
    @name ||= "#{mark}_#{number}"
  end

  def id()
    @id ||= "id:#{name}"
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

  def open(sec = 0)
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
    self.class.markColor mark
  end

  def count()
    reduce(0) {|n| n + 1}
  end

  def last?()
    place.last == self
  end

  def canDrop?()
    @game.canDrop? self
  end

  def <=>(o)
    number != o.number ? number <=> o.number :
                           mark <=> o.mark
  end

  def sprite()
    @sprite ||= Sprite.new(0, 0, *spriteSize, image: closedImage).tap do |sp|
      sp.pivot = [rand, rand]
      sp.angle = rand -5.0..5.0
      sp.update do
        sp.image = @open > 90 ? openedImage : closedImage
      end
      sp.draw do |&draw|
        push do
          px, py = *sp.pivot
          translate  px,  py
          rotate    -sp.angle
          translate  2,  5
          rotate     sp.angle
          translate -px, -py
          fill 0, 50
          rect 0, 0, w, h, 4
        end
        translate  sp.w / 2,  sp.h / 2
        rotate @open
        translate -sp.w / 2, -sp.h / 2
        image sp.image, 0, 0, w, h
      end
      sp.mousePressed do
        mousePressed sp.mouseX, sp.mouseY
      end
      sp.mouseReleased do
        mouseReleased sp.mouseX, sp.mouseY, sp.clickCount
      end
      sp.mouseDragged do
        x, y = sp.mouseX, sp.mouseY
        mouseDragged x, y, x - sp.pmouseX, y - sp.pmouseY
      end
    end
  end

  def inspect()
    "#<Card #{name}>"
  end

  private

  def mousePressed(x, y)
    @prevPlace = place
    @startPos  = createVector x, y, self.z
    hover
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

  def openedImage()
    @openedImage ||= createGraphics(*self.class.cardSize).tap do |g|
      c, w, h, m     = self.class, g.width, g.height, 16# margin
      image          = c.cardImage
      nx, ny, nw, nh = c.numberRect number
      mx, my, mw, mh = c.markRect mark
      mnh            = m + nh
      mxx, myy       = (w - mw) / 2, mnh + ((h - mnh) - mh) / 2
      g.beginDraw
      g.angleMode DEGREES
      g.translate  w / 2,  h / 2
      g.rotate 180
      g.translate -w / 2, -h / 2
      g.copy image, 896,  0, w,  h,  0,   0,   w,  h
      g.tint *c.markColor(mark)
      g.copy image, nx, ny,  nw, nh, m,   m,   nw, nh
      g.copy image, mx, my,  mw, mh, mxx, myy, mw, mh
      g.endDraw
    end
  end

  def closedImage()
    self.class.closedImages[self.class.closedImageIndex]
  end

  def spriteSize()
    self.class.spriteSize
  end

  def self.closedImages()
    @closedImages ||= (0..3).map {|n| n * 256}.map do |x|
      createGraphics(*cardSize).tap do |g|
        w, h = g.width, g.height
        g.beginDraw
        g.copy cardImage, x, 256, w, h, 0, 0, w, h
        g.endDraw
      end
    end
  end

  def self.closedImageIndex()
    @closedImageIndex ||= (0...closedImages.size).to_a.sample.tap {|o| p o}
  end

  def self.useNextClosedImage()
    @backgroundColors = @redColor = @blackColor = @buttonColor = nil
    @closedImageIndex = (closedImageIndex + 1) % closedImages.size
  end

  def self.backgroundColors()
    @backgroundColors ||= colors[closedImageIndex][0, 2]
  end

  def self.redColor()
    @redColor ||= colors[closedImageIndex][2]
  end

  def self.blackColor()
    @blackColor ||= colors[closedImageIndex][3]
  end

  def self.buttonColor()
    @buttonColor ||= colors[closedImageIndex][4]
  end

  def self.colors()
    @colors ||= [
      [[120, 106, 104], [100, 96,  95],  [255, 97,  82], [62, 46, 45], [255, 97,  82]],
      [[98,  101, 99],  [92,  95,  96],  [255, 94,  77], [32, 48, 55], [117, 135, 124]],
      [[130, 100, 90],  [106, 100, 97],  [255, 110, 65], [64, 49, 43], [255, 137, 99]],
      [[111, 103, 95],  [107, 110, 111], [255, 80,  0],  [40, 60, 63], [255, 132, 0]],
    ]
  end

  def self.cardImage()
    @cardImage ||= loadImage dataPath 'card.png'
  end

  def self.cardSize()
    [164, 252]
  end

  def self.spriteSize()
    @spriteSize ||= cardSize.then do |cw, ch|
      ncolumns   = 7
      size       = [width, height].min
      cardWidth  = (size - margin * (ncolumns + 1)) / ncolumns
      [cardWidth, cardWidth * (ch.to_f / cw.to_f)]
    end
  end

  def self.margin()
    @marin ||= [width, height].min * 0.02
  end

  def self.markRect(mark)
    w = h = 128
    [MARKS.index(mark) * w, 0, w, h]
  end

  def self.numberRect(number)
    w = h = 64
    [(number - 1) * w, 128, w, h]
  end

  def self.markColor(mark)
    MARKS[0, 2].include?(mark) ? redColor : blackColor
  end

end# Card
