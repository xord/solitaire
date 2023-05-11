using RubySketch


EASINGS = {
  quadIn:  lambda { |x| x * x },
  expoOut: lambda { |x| 1.0 - 2 ** (-10 * x.clamp(0.0, 1.0)) }
}


def animate(name = unique, seconds, ease: :expoOut, &block)
  fun = EASINGS[ease]
  start = now
  eachDrawBlock = lambda do
    t = (now - start) / seconds
    if t >= 1.0
      block.call fun.call(1.0), true, 1.0
    else
      block.call fun.call(t), false, t
      startTimer name, 0, &eachDrawBlock
    end
  end
  startTimer name, 0, &eachDrawBlock
end

def move(obj, toPos, seconds, **kwargs, &block)
  from = createVector obj.x, obj.y
  to   = createVector *toPos.to_a[0, 2]
  animate seconds, **kwargs do |t, *args|
    obj.pos = Vector.lerp(from, to, t)
    block&.call t, *args
  end
end
