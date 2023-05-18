using RubySketch


class Scene

  def initialize(name = self.class.name, *scenes)
    @name, @scenes = name, []
    add *scenes unless scenes.empty?
  end

  attr_reader :name, :parent

  def add(*scenes)
    @scenes.push *scenes
    scenes.each do |scene|
      scene.parent = self
      scene.activated
    end
  end

  def remove(*scenes)
    @scenes.delete_if {|scene| scenes.include? scene}
    scenes.each do |scene|
      scene.deactivated
      scene.parent = nil
    end
  end

  def transition(to)
    parent.add to
    parent.remove self
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

  def draw()
    @scenes.each do |scene|
      push {scene.draw}
    end
    particle.draw
  end

  def activated()
    sprites.each {|sprite| addSprite sprite}
  end

  def deactivated()
    sprites.each {|sprite| removeSprite sprite}
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
