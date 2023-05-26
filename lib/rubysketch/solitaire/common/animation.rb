using RubySketch


EASINGS = {
  linear:  lambda { |x| x },
   sineIn: lambda { |x| 1.0 - Math.cos(x * Math::PI / 2) },
  sineOut: lambda { |x|       Math.sin(x * Math::PI / 2) },

     quadIn: lambda { |x|    quadIn x },
    cubicIn: lambda { |x|   cubicIn x },
    quartIn: lambda { |x|   quartIn x },
    quintIn: lambda { |x|   quintIn x },
     circIn: lambda { |x|    circIn x },
     backIn: lambda { |x|    backIn x },
     expoIn: lambda { |x|    expoIn x },
  elasticIn: lambda { |x| elasticIn x },
   bounceIn: lambda { |x| 1.0 - bounceOut(1.0 - x) },

     quadOut: lambda { |x| 1.0 -    quadIn(1.0 - x) },
    cubicOut: lambda { |x| 1.0 -   cubicIn(1.0 - x) },
    quartOut: lambda { |x| 1.0 -   quartIn(1.0 - x) },
    quintOut: lambda { |x| 1.0 -   quintIn(1.0 - x) },
     circOut: lambda { |x| 1.0 -    curcIn(1.0 - x) },
     backOut: lambda { |x| 1.0 -    backIn(1.0 - x) },
     expoOut: lambda { |x| 1.0 -    expoIn(1.0 - x) },
  elasticOut: lambda { |x| 1.0 - elasticIn(1.0 - x) },
   bounceOut: lambda { |x| bounceOut x },

     sineInOut: lambda { |x| x < 0.5 ?    sineIn(x) :    sineOut(x) },
     quadInOut: lambda { |x| x < 0.5 ?    quadIn(x) :    quadOut(x) },
    cubicInOut: lambda { |x| x < 0.5 ?   cubicIn(x) :   cubicOut(x) },
    quartInOut: lambda { |x| x < 0.5 ?   quartIn(x) :   quartOut(x) },
    quintInOut: lambda { |x| x < 0.5 ?   quintIn(x) :   quintOut(x) },
     circInOut: lambda { |x| x < 0.5 ?    circIn(x) :    circOut(x) },
     backInOut: lambda { |x| x < 0.5 ?    backIn(x) :    backOut(x) },
     expoInOut: lambda { |x| x < 0.5 ?    expoIn(x) :    expoOut(x) },
  elasticInOut: lambda { |x| x < 0.5 ? elasticIn(x) : elasticOut(x) },
   bounceInOut: lambda { |x| x < 0.5 ?  bounceIn(x) :  bounceOut(x) }
}

def quadIn(x)
  x ** 2
end

def cubicIn(x)
  x ** 3
end

def quartIn(x)
  x ** 4
end

def quintIn(x)
  x ** 5
end

def circIn(x)
  1.0 - Math.sqrt(1.0 - x ** 2)
end

def backIn(x)
  2.70158 * x ** 3 - 1.70158 * x ** 2
end

def expoIn(x)
  x == 0 ? 0.0 : 2.0 ** (10.0 * x - 10.0)
end

def elasticIn(x)
  c = Math::PI * 2.0 / 3.0
  case x
  when 0 then 0
  when 1 then 1
  else -(2 ** (10.0 * x - 10.0)) * Math.sin((x * 10.0 - 10.75) * c)
  end
end

def bounceOut(x)
  n1, d1 = 7.5625, 2.75
  case
  when x < 1.0 / d1 then                  n1 * x * x
  when x < 2.0 / d1 then x -= 1.5   / d1; n1 * x * x + 0.75;
  when x < 2.5 / d1 then x -= 2.25  / d1; n1 * x * x + 0.9375;
  else                   x -= 2.625 / d1; n1 * x * x + 0.984375;
  end
end


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

def animateValue(name = unique, seconds, from:, to:, **kwargs, &block)
  animate name, seconds, **kwargs do |t, finished, tt|
    block.call lerp(from, to, t), finished, t, tt
  end
end

def move(obj, toPos, seconds, **kwargs, &block)
  from, to = obj.pos.dup, toPos.dup
  animate seconds, **kwargs do |t, *args|
    obj.pos = Vector.lerp(from, to, t)
    block&.call t, *args
  end
end
