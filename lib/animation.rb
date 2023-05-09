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

def move(obj, toPos, seconds, &block)
  from = createVector obj.x, obj.y
  to   = createVector *toPos.to_a[0, 2]
  animate seconds do |t, finished|
    obj.pos = Vector.lerp(from, to, t).then {|v| [v.x, v.y]}
    block&.call if finished
  end
end
