# -*- coding: utf-8 -*-
using RubySketch


class Background < Scene

  TYPES = {
    checker:        {name: 'Checker'},
    checker2:       {name: 'Checker (No Scroll)'},
    cosmic2:        {name: 'Cosmic 2',         author: 'huwb',
      url: 'https://www.shadertoy.com/view/XllGzN'},
    classicPSPWave: {name: 'Classic PSP Wave', author: 'ParkingLotGames',
      url: 'https://www.shadertoy.com/view/ddV3DK'},
  }

  def initialize(type = nil)
    super
    @start = now
    set type || settings['background']&.intern|| types.first
  end

  attr_reader :type

  def types()
    TYPES.keys
  end

  def name()
    TYPES[type][:name]
  end

  def author()
    TYPES[type][:author]
  end

  def url()
    TYPES[type][:url]
  end

  def nextType()
    index = types.index(@type) || 0
    types[(index + 1) % types.size]
  end

  def set(type)
    type = types.first unless types.include?(type)
    case type
    when :checker, :checker2
      @shader = createShader nil, checker
      @canvas = createGraphics width, height
    when :cosmic2
      @shader = createShader nil, cosmic2
      @canvas = createGraphics width, height#, displayDensity
    when :classicPSPWave
      @shader = createShader nil, classicPSPWave
      @canvas = createGraphics width, height#, displayDensity
    end
    settings['background'] = @type = type
  end

  def draw()
    @canvas.beginDraw do |g|
      sh = @shader
      case type
      when :checker, :checker2
        colors = skin.backgroundCheckerColors
        sh.set :iTime, (type == :checker2 ? 0.0 : now - @start)
        sh.set :color1, *colors[0].map {|n| n / 255.0}
        sh.set :color2, *colors[1].map {|n| n / 255.0}
      when :cosmic2
        sh.set :iTime, now - @start
        sh.set :iResolution, width, height
      when :classicPSPWave
        sh.set :iTime, now - @start
        sh.set :iResolution, width, height
      end
      g.shader sh
      g.rect 0, 0, g.width, g.height
    end
    copy @canvas, 0, 0, @canvas.width, @canvas.height, 0, 0, width, height
  end

  private

  def checker()
    <<~END
      varying vec4 vertTexCoord;
      uniform float iTime;
      uniform vec4 color1;
      uniform vec4 color2;
      void main() {
        float t = mod(iTime, 32.) * 8.;
        float x = mod(vertTexCoord.x + t, 32.) < 16. ? 1. : 0.;
        float y = mod(vertTexCoord.y + t, 32.) < 16. ? 1. : 0.;
        gl_FragColor = x != y ? color1 : color2;
      }
    END
  end

  def cosmic2()
    # Cosmic 2
    # https://www.shadertoy.com/view/XllGzN
    File.read(dataPath 'cosmic2.glsl').gsub('iMouse', 'vec2(0.)')
  end

  def classicPSPWave()
    # Classic PSP Wave
    # https://www.shadertoy.com/view/ddV3DK
    File.read(dataPath 'classicPSPWave.glsl')
  end

end# Background
