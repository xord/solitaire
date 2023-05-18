require 'solitaire'
using RubySketch


SW = 375 # screen width
SH = 667


setup do
  setTitle "Solitaire"
  size SW, SH
  angleMode DEGREES
  noStroke

  $root = Scene.new 'Root', Background.new, Title.new
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
