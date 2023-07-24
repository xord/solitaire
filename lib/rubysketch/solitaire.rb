require 'forwardable'
require 'rbconfig'
require 'uri'
require 'json'
require 'rubysketch'

require 'rubysketch/common'

require 'rubysketch/solitaire/skin'
require 'rubysketch/solitaire/card'
require 'rubysketch/solitaire/places'

require 'rubysketch/solitaire/background'
require 'rubysketch/solitaire/start'
require 'rubysketch/solitaire/klondike'


using RubySketch


def debug?()
  $debug || ENV['DEBUG'] || false
end

def sendCommand(type, *args)
  $command = [type, *args].map {|s| URI.encode_www_form_component s}.join ':'
end

def settings()
  $settings ||= Settings.new 'solitaire.json'
end

def skin(index = nil)
  $skin = nil if index != nil && index != $skin.index
  $skin ||= Skin.new index || settings['skinIndex'] || 0
end

def backgroundScene()
  $backgroundScene ||= Background.new
end

def checkFocus()
  $prevFocused = focused if $prevFocused == nil
  $root.focusChanged focused if focused != $prevFocused
  $prevFocused = focused
end

setup do
  setTitle "Solitaire"
  size 375, 667 unless $nosize
  windowMove *windowPos
  windowResizable false
  angleMode DEGREES
  noStroke

  Skin.setup
  $root = RootScene.new 'Root', backgroundScene, Start.new
end

draw do
  checkFocus
  drawShake
  push {$root.draw}
end

def windowPos()
  settings['windowPos'] || [
    (displayWidth  - windowWidth)  / 2,
    (displayHeight - windowHeight) / 2
  ]
end

windowMoved do
  settings['windowPos'] = [windowX, windowY]
end

mousePressed do
  $root.mousePressed mouseX, mouseY, mouseButton
end

mouseReleased do
  $root.mouseReleased mouseX, mouseY, mouseButton
end

mouseMoved do
  $root.mouseMoved mouseX, mouseY, mouseX - pmouseX, mouseY - pmouseY
end

mouseDragged do
  $root.mouseDragged mouseX, mouseY, mouseX - pmouseX, mouseY - pmouseY
end
