using RubySketch


class Scene

  def initialize(name = self.class.name, *scenes)
    @name     = name
    @scenes   = []
    @active   = self.class == RootScene
    @prevSize = [width, height]
    resized *@prevSize
    scenes.each {|scene| add scene}
  end

  attr_reader :name, :parent

  def pause()
  end

  def resume()
  end

  def add(scene)
    @scenes.push scene
    scene.parent = self
    scene.activated if active?
    scene
  end

  def remove(scene)
    @scenes.delete scene
    scene.deactivated if active?
    scene.parent = nil
    scene
  end

  def transition(to, effect = nil, *args, **kwargs)
    if effect
      add effect.new(to, *args, **kwargs)
    else
      parent.add to
      parent.remove self
    end
    to
  end

  def emitParticle(x, y, w, h, sec = nil, &block)
    par   = particle.new x, y, w, h
    start = now
    par.update do
      time   = now - start
      t      = sec ? time / sec : nil
      result = block&.call time, t
      if result == false || (t || 1) >= 1
        par.update {}
        par.delete
      end
    end
    par
  end

  def sprites()
    particle.sprites
  end

  def particle()
    @particle ||= Particle.new
  end

  def update()
    size = [width, height]
    if size != @prevSize
      resized(*size)
      @prevSize = size
    end
  end

  def draw()
    update
    @scenes.each do |scene|
      push {scene.draw}
    end
    push do
      blendMode ADD
      particle.draw
    end
  end

  def resized(w, h)
  end

  def activated()
    @active = true
    @scenes.each {|scene| scene.activated}
    sprites.each {|sprite| addSprite sprite}
  end

  def deactivated()
    sprites.each {|sprite| removeSprite sprite}
    @scenes.each {|scene| scene.deactivated}
    @active = false
  end

  def active?()
    @active
  end

  def mousePressed(x, y, button)
    @scenes.each {|scene| scene.mousePressed x, y, button}
  end

  def mouseReleased(x, y, button)
    @scenes.each {|scene| scene.mouseReleased x, y, button}
  end

  def mouseMoved(x, y, dx, dy)
    @scenes.each {|scene| scene.mouseMoved x, y, dx, dy}
  end

  def mouseDragged(x, y, dx, dy)
    @scenes.each {|scene| scene.mouseDragged x, y, dx, dy}
  end

  protected

  def parent=(scene)
    @parent = scene
  end

end# Scene


class RootScene < Scene
end# RootScene
