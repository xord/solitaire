using RubySketch


class Card

  include HasSprite
  include Enumerable
  include Comparable

  MARKS = %i[heart diamond clover spade]

  def initialize(game, mark, number)
    @game, @mark, @number = game, mark, number
    @state, @open, @flash = :close, 0, 0
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

  def flash()
    animateValue(3, from: 200, to: 0) {@flash = _1}
    setTimeout(0.01) {@next.flash} if @next
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
    skin.markColor mark
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
    @sprite ||= Sprite.new(
      0, 0, *skin.cardSpriteSize, image: skin.closedImage
    ).tap do |sp|
      sp.pivot = [rand, rand]
      sp.angle = rand -5.0..5.0
      sp.update do
        sp.image = @open > 90 ? skin.openedImage(mark, number) : skin.closedImage
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
        if @flash > 0
          push do
            blendMode ADD
            fill 255, @flash
            rect 0, 0, w, h, 4
          end
        end
      end
      sp.mousePressed do
        next if $dragging
        $dragging = self
        mousePressed sp.mouseX, sp.mouseY
      end
      sp.mouseReleased do
        next unless $dragging.object_id == self.object_id
        mouseReleased sp.mouseX, sp.mouseY, sp.clickCount
        $dragging = nil
      end
      sp.mouseDragged do
        next unless $dragging.object_id == self.object_id
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
    pos    = sprite.toScreen createVector x, y
    @game.cardDropped pos.x, pos.y, self, @prevPlace if
      @prevPlace && clickCount == 0
  end

  def mouseDragged(x, y, dx, dy)
    self.pos += createVector x - @startPos.x, y - @startPos.y if @startPos
  end

end# Card
