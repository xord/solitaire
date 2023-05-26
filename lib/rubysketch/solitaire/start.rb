using RubySketch


class Start < Scene

  def activated()
    super
    transition (resume || Klondike.new), Fade, secOut: 0
  end

  private

  def resume(path = STATE_PATH)
    state = JSON.parse File.read(path)
    klass = [Klondike].find {|c| c.name == state['game']}
    klass&.new state
  rescue
    nil
  end

end# Start
