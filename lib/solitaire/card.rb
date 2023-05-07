# -*- coding: utf-8 -*-
using RubySketch


class Card

  include HasSprite

  MARKS = %i[heart diamond clover spade]

  def initialize(mark, number)
    @mark, @number, @state = mark, number, :close
  end

  attr_reader :mark, :number

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

  def toggle()
    closed? ? open : close
  end

  def placed(place)
    @place = place
  end

  def sprite()
    @sprite ||= Sprite.new(image: closedImage).tap do |sp|
      sp.pivot = [0.5, 0.5]
      sp.angle = rand -5..5
      sp.update do
        sp.image = opened? ? openedImage : closedImage
      end
    end
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

end# Card


class CardOld < GameObject
  def initialize(mark, number)
    super CW, CH
    @mark, @number, @state = mark, number, :close
    @place = @next = nil
  end

  attr_reader :mark, :number

  attr_accessor :place, :next

  def x=(x)
    old = self.x
    super
    self.next&.tap { _1.x += self.x - old }
  end

  def y=(y)
    old = self.y
    super
    self.next&.tap { _1.y += self.y - old }
  end

  def z=(z)
    old = self.z
    super
    self.next&.tap { _1.z += self.z - old }
  end

  def state=(state)
    raise ArgumentError unless [:open, :close].include?(state)
    @state = state
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

  def last?
    self.next == nil && self == place&.cards.last
  end

  def each()
    card = self
    while card
      yield card
      card = card.next
    end
    self
  end

  def draw()
    opened? ? drawFace : drawBack
  end

  def red?()
    %w[❤ ♦].include? @mark
  end

  private

  NUM_SYMBOLS = { 11 => :J, 12 => :Q, 13 => :K }

  def drawFace()
    @face ||= createGraphics(w, h).tap do |g|
      g.beginDraw do
        drawBackground g, 255, 0
        g.fill(*(red? ? [255, 0, 0] : 0))
        g.textAlign CENTER, CENTER
        s = @w / 2
        g.textSize 40
        g.text @mark, 2, 0, s, s
        g.text NUM_SYMBOLS[@number] || @number, s - 2, 0, s, s
        g.textSize 60
        g.text @mark, 0, s, @w, @h - s
      end
    end
    image @face, 0, 0
  end

  def drawBack()
    drawBackground self, [200, 100, 100], 200
  end

  def drawBackground(g, color, strokeColor)
    g.fill *color
    g.stroke *strokeColor
    g.strokeWeight 2
    g.rect 0, 0, @w, @h, @w / 10
  end
end
