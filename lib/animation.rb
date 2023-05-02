using RubySketch


OUT_EXPO = lambda { |x| 1.0 - 2 ** (-10 * x.clamp(0.0, 1.0)) }


def animate(name = unique, seconds, ease: OUT_EXPO, &block)
  start = now
  eachDrawBlock = lambda do
    t = (now - start) / seconds
    if t >= 1.0
      block.call ease.call(1.0), true
    else
      block.call ease.call(t), false
      startTimer name, 0, &eachDrawBlock
    end
  end
  startTimer name, 0, &eachDrawBlock
end

def move(obj, toPos, seconds, zOnMove: nil, &block)
  from = createVector obj.x, obj.y, obj.z
  to = createVector *toPos
  animate seconds do |t, finished|
    obj.pos = Vector.lerp(from, to, t).then { [_1.x, _1.y, _1.z] }
    obj.z = zOnMove if zOnMove && !finished
    block&.call if finished
  end
end

def moveCard(card, toPlace, seconds, zOnMove: nil, &block)
  fromPos = card.pos
  toPlace.add card
  toPos = card.pos.dup
  card.pos = fromPos
  move card, toPos, seconds, zOnMove: zOnMove, &block
end
