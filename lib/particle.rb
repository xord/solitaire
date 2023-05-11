using RubySketch


class Particle

  include HasSprite

  def initialize()
    @sprites = []
    @pool    = []
  end

  attr_reader :sprites

  def new(x, y, w, h, &block)
    sp = newSprite x, y, w, h
    addSprite sp
    @sprites.push sp
    block.call sp if block
    sp
  end

  def delete(sprite)
    @sprites.delete sprite
    removeSprite sprite
    @pool.push sprite
    sprite
  end

  def draw()
    drawSprite @sprites
  end

  private

  def newSprite(x, y, w, h)
    popSprite(x, y, w, h) || ParticleSprite.new(self, x, y, w, h)
  end

  def popSprite(x, y, w, h)
    @pool.pop&.tap do |sp|
      sp.frame = [x, y, w, h]
    end
  end

end# Particle


class ParticleSprite < Sprite

  def initialize(owner, *args, rgb: [255], alpha: 255, **kwargs, &block)
    @owner, @rgb, @alpha = owner, rgb, alpha
    super(*args, **kwargs, &block)
    draw do |&draw|
      fill *@rgb, @alpha
      draw.call
    end
  end

  attr_accessor :rgb, :alpha

  def frame=(frame)
    self.pos  = frame[0, 2]
    self.size = frame[2, 2]
  end

  def delete()
    @owner.delete self
  end

end# ParticleSprite
