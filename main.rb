require 'solitaire'
using RubySketch


SW = 240 # screen width
SH = 320
CW = 32 # card width
CH = 46 # CW * 89 / 58


setup do
  setTitle "Solitaire"
  size SW, SH
  angleMode DEGREES
  noStroke

  $clickCount = $clickPrevTime = 0
  $root = Scene.new 'Root', Background.new, Title.new
end

draw do
  fireTimers
  drawShake
  push { $root.draw }
end

mousePressed do
  $clickCount    = (now - $clickPrevTime) < 0.3 ? $clickCount + 1 : 1
  $clickPrevTime = now
  $root.mousePressed mouseX, mouseY, mouseButton, $clickCount
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
