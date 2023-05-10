using RubySketch


class Background < Scene

  def initialize()
    super
    @start  = now
    @shader = createShader nil, <<~END
      varying vec4 vertTexCoord;
      uniform float time;
      void main() {
        float t = mod(time, 32.0) * 16.0;
        float x = mod(vertTexCoord.x + t, 32.0) < 16.0 ? 1.0 : 0.0;
        float y = mod(vertTexCoord.y + t, 32.0) < 16.0 ? 1.0 : 0.0;
        gl_FragColor = x != y ? vec4(0.6, 0.9, 0.7, 1) : vec4(0.7, 0.9, 0.6, 1);
      }
    END
  end

  def draw()
    pushStyle do
      @shader.set :time, now - @start
      shader @shader
      rect 0, 0, width, height
    end
  end

end# Background