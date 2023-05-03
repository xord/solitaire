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

  def sprites()
    []
  end

  def draw()
    @scenes.each do |scene|
      push {scene.draw}
    end
  end

  def activated()
    sprites.each {|sprite| addSprite sprite}
  end

  def deactivated()
    sprites.each {|sprite| removeSprite sprite}
  end

  def mousePressed(x, y, button, clickCount)
    @scenes.each {|scene| scene.mousePressed x, y, button, clickCount}
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
