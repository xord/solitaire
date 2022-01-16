draw do
    background 0
    rect 100, 100, 100, 100
    text frameRate.to_i, 10, 30
end

mousePressed do
    ellipse mouseX, mouseY, 50, 50
end
