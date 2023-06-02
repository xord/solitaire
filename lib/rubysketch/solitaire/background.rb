using RubySketch


class Background < Scene

  def initialize(type = nil)
    super
    @start = now
    set type || settings['background']&.intern|| types.first
  end

  def types()
    %i[checker space]
  end

  def nextType()
    types[(types.index(@current) + 1) % types.size]
  end

  def set(type)
    case type
    when :checker
      @shader   = checker
      @canvas   = createGraphics width, height
      @uniforms = %i[iTime]
      @interval = 3
    when :space
      @shader   = space
      @canvas   = createGraphics width, height, displayDensity
      @uniforms = %i[iTime iResolution]
      #@canvas.filter BLUR, 2
      @interval = 1
    end
    @current               = type
    settings['background'] = type
  end

  def draw()
    @canvas.beginDraw do |g|
      sh = @shader
      sh.set :iTime, now - @start        if @uniforms.include?(:iTime)
      sh.set :iResolution, width, height if @uniforms.include?(:iResolution)
      g.shader sh
      g.rect 0, 0, g.width, g.height
    end if frameCount % @interval == 0
    copy @canvas, 0, 0, @canvas.width, @canvas.height, 0, 0, width, height
  end

  private

  def checker()
    @checker ||= createShader nil, <<~END
      varying vec4 vertTexCoord;
      uniform float iTime;
      void main() {
        float t = mod(iTime, 32.0) * 16.0;
        float x = mod(vertTexCoord.x + t, 32.0) < 16.0 ? 1.0 : 0.0;
        float y = mod(vertTexCoord.y + t, 32.0) < 16.0 ? 1.0 : 0.0;
        gl_FragColor = x != y ? vec4(0.6, 0.9, 0.7, 1) : vec4(0.7, 0.9, 0.6, 1);
      }
    END
  end

  def space()
    @space ||= createShader nil, <<~END.sub('0.010', '0.002').gsub('iMouse', 'vec2(0.)')
      // https://www.shadertoy.com/view/XlfGRj
      // Star Nest by Pablo Roman Andrioli
      // License: MIT

      #define iterations 17
      #define formuparam 0.53

      #define volsteps 20
      #define stepsize 0.1

      #define zoom   0.800
      #define tile   0.850
      #define speed  0.010

      #define brightness 0.0015
      #define darkmatter 0.300
      #define distfading 0.730
      #define saturation 0.850

      void mainImage( out vec4 fragColor, in vec2 fragCoord )
      {
        //get coords and direction
        vec2 uv=fragCoord.xy/iResolution.xy-.5;
        uv.y*=iResolution.y/iResolution.x;
        vec3 dir=vec3(uv*zoom,1.);
        float time=iTime*speed+.25;

        //mouse rotation
        float a1=.5+iMouse.x/iResolution.x*2.;
        float a2=.8+iMouse.y/iResolution.y*2.;
        mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
        mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
        dir.xz*=rot1;
        dir.xy*=rot2;
        vec3 from=vec3(1.,.5,0.5);
        from+=vec3(time*2.,time,-2.);
        from.xz*=rot1;
        from.xy*=rot2;

        //volumetric rendering
        float s=0.1,fade=1.;
        vec3 v=vec3(0.);
        for (int r=0; r<volsteps; r++) {
          vec3 p=from+s*dir*.5;
          p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
          float pa,a=pa=0.;
          for (int i=0; i<iterations; i++) {
            p=abs(p)/dot(p,p)-formuparam; // the magic formula
            a+=abs(length(p)-pa); // absolute sum of average change
            pa=length(p);
          }
          float dm=max(0.,darkmatter-a*a*.001); //dark matter
          a*=a*a; // add contrast
          if (r>6) fade*=1.-dm; // dark matter, don't render near
          //v+=vec3(dm,dm*.5,0.);
          v+=fade;
          v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
          fade*=distfading; // distance fading
          s+=stepsize;
        }
        v=mix(vec3(length(v)),v,saturation); //color adjust
        fragColor = vec4(v*.01,1.);
      }
    END
  end

end# Background
