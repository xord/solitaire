using RubySketch


class Title < Scene

  def initialize()
    super
    @sprites =
      if @suspended = Klondike.load rescue nil
        resumeButton.y = 400
        startButton.y  = 460
        [title, resumeButton, startButton]
      else
        startButton.y  = 400
        [title, startButton]
      end
    title.y = 200
  end

  attr_reader :sprites

  def draw()
    sprite sprites
  end

  private

  def title()
    @title ||= Sprite.new(0, 0, width, 50).tap do |sp|
      sp.draw do
        textAlign CENTER, CENTER
        textSize 80
        text 'Solitaire', 0, 0, sp.w, sp.h
      end
    end
  end

  def startButton()
    @startButton ||= Button.new('NEW GAME', [140, 180, 160], 4).tap do |sp|
      sp.update do
        sp.x = (width - sp.w) / 2
      end
      sp.clicked do
        startTimer(0) {transition Klondike.new}
      end
    end
  end

  def resumeButton()
    @resumeButton ||= Button.new('RESUME GAME', [140, 180, 160], 4).tap do |sp|
      sp.update do
        sp.x = (width - sp.w) / 2
      end
      sp.clicked do
        startTimer(0) {transition @suspended}
      end
    end
  end

end# Title
