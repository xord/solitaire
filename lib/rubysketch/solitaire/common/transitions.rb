using RubySketch


class TransitionEffect < Scene

  def initialize(
    nextScene, sec: 1,
     secOut: nil,       secIn: nil,
    easeOut: :expoOut, easeIn: :expoIn,
    showAd: false,
    &block)

    super()
    @nextScene, @easeOut, @easeIn, @showAd, @block =
      nextScene, easeOut, easeIn, showAd, block
    @secOut = secOut || sec / 2.0
    @secIn  = secIn  || sec / 2.0
    @phase  = :out
  end

  attr_reader :phase

  def effect(t)
  end

  def activated()
    super
    start do
      case @phase
      when :out
        sendCommand :showInterstitialAd if @showAd
        delay do
          pa = parent
          pa.remove self
          @phase = :in
          @nextScene.add self
          pa.transition @nextScene
          @block.call if @block
        end
      when :in
        parent.remove self
      end
    end
  end

  private

  def start(&block)
    sec  = out? ? @secOut  : @secIn
    ease = out? ? @easeOut : @easeIn
    animate sec, ease: ease do |t, finished|
      effect (out? ? t : 1.0 - t)
      block.call if finished
    end
  end

  def out?()
    @phase == :out
  end

end# TransitionEffect


class Fade < TransitionEffect

  def initialize(*args, rgb: 0, **kwargs, &block)
    super(*args, easeIn: :expoOut, **kwargs)
    @rgb, @alpha = rgb, 0
  end

  def effect(t)
    @alpha = 255 * t
  end

  def draw()
    super
    fill *@rgb, @alpha
    noStroke
    rect 0, 0, width, height
  end

end# Fade


class Curtain < TransitionEffect

  def initialize(*args, rgb: 0, **kwargs, &block)
    super(*args, easeIn: :expoOut, **kwargs)
    @rgb = rgb
    @y = @h = 0
  end

  def effect(t)
    @y, @h =
      case phase
      when :out then [height * (1.0 - t), height]
      when :in  then [0,                  height * t]
      end
  end

  def draw()
    super
    fill *@rgb
    noStroke
    rect 0, @y, width, @h
  end

end# Fade


class Pixelate < TransitionEffect

  def initialize(*args, **kwargs, &block)
    super *args, sec: 1, easeOut: :cubicOut, easeIn: :cubicIn, **kwargs, &block
  end

  def activated()
    super
    filter pixelate
  end

  def deactivated()
    super
    filter nil
  end

  def effect(t)
    pixelate.set :resolution,   width, height
    pixelate.set :pixelateSize, map(t, 0.0, 1.0, 1, 32)
  end

  private

  def pixelate()
    @checker ||= createShader nil, <<~END
      uniform sampler2D texMap;
      uniform vec3 texMax;
      uniform vec2 resolution;
      uniform float pixelateSize;
      varying vec4 vertTexCoord;
      varying vec4 vertColor;
      void main() {
        vec2 r     = resolution;
        float ps   = pixelateSize;
        vec2 coord = (floor(vertTexCoord.xy * r / ps) + 0.5) * ps / r;
        if (coord.x >= texMax.x) coord.x = texMax.x - 1. / r.x;
        if (coord.y >= texMax.y) coord.y = texMax.y - 1. / r.y;

        vec4 col     = texture2D(texMap, coord);
        gl_FragColor = vec4(col.rgb, 1.) * vertColor;
      }
    END
  end

end# Pixelate
