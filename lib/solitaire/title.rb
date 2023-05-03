using RubySketch


class Title < Scene

  def initialize()
    super
    @sprites = [title, tapToStart]
    title.y      = 100
    tapToStart.y = 170
  end

  attr_reader :sprites

  def draw()
    sprite sprites
  end

  def mousePressed(*args)
    transition Klondike.new
  end

  private

  def title()
    @title ||= Sprite.new(0, 0, width, 50).tap do |sp|
      sp.draw do
        textAlign CENTER, CENTER
        textSize 50
        text 'Solitaire', 0, 0, sp.w, sp.h
        fill 100, 100, 100, 100
        rect 0, 0, sp.w, sp.h
      end
    end
  end

  def tapToStart()
    @tapToStart ||= Sprite.new(0, 0, width, 20).tap do |sp|
      sp.draw do
        next if frameCount % 120 < 60
        textAlign CENTER, CENTER
        textSize 20
        text 'Tap to Start!', 0, 0, sp.w, sp.h
        fill 100, 100, 100, 100
        rect 0, 0, sp.w, sp.h
      end
    end
  end

end# Title
