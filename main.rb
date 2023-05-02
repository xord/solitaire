require 'utils'
require 'timer'
require 'animation'
require 'object'
require 'solitaire/background'
require 'solitaire/card'
#require 'solitaire/places'
#require 'solitaire/game'

using RubySketch


MARKS = %i[heart diamond clover spade]

CW = 32 # card width
CH = 46 #CW * 89 / 58


$ground = createSprite -100, 366, 600, 10
$ground.friction = 1


class Game
  def initialize()
    @background = Background.new
    @cards = MARKS.product((1..13).to_a).map {|m, n| Card.new m, n}
    @sprites = @cards.map &:sprite
    @sprites.reverse.each.with_index do |sp, index|
      addSprite sp
      sp.contact? {_1 == $ground}
      sp.pos = [rand(width - CW), 20]
      startTimer 3 + index * 0.1 do
        sp.dynamic = true
        sp.friction = 1
        sp.restitution = 0.5
        sp.vel = [rand(-50..50), 0]
      end
    end
  end

  def draw()
    @background.draw
    sprite @sprites
  end

  def mouseClicked(x, y, clickCount)
  end

  def mousePressed(x, y)
  end

  def mouseReleased(x, y)
  end

  def mouseDragged(x, y, prevX, prevY)
  end
end


setup do
  size 240, 320
  gravity 0, 500
  #$clickCount = $clickPrevTime = 0
  $game = Game.new
end

draw do
  fireTimers
  push { $game.draw }
  sprite $ground
end

mouseClicked do
  #$clickCount = (now - $clickPrevTime) < 0.3 ? $clickCount + 1 : 1
  $clickPrevTime = now
  $game.mouseClicked mouseX, mouseY, $clickCount
end

mousePressed do
  $game.mousePressed mouseX, mouseY
end

mouseReleased do
  $game.mouseReleased mouseX, mouseY
end

mouseDragged do
  $game.mouseDragged mouseX, mouseY, pmouseX, pmouseY
end
