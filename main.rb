require 'solitaire'
using RubySketch


SCREEN_WIDTH  = 375 # screen width
SCREEN_HEIGHT = 667
STATE_PATH    = 'state.json'
SCORES_PATH   = 'scores.json'


setup do
  setTitle "Solitaire"
  size SCREEN_WIDTH, SCREEN_HEIGHT
  angleMode DEGREES
  noStroke

  $root = RootScene.new 'Root', Background.new, Start.new
end

draw do
  fireTimers
  drawShake
  push { $root.draw }
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
