using RubySketch


class Start < Scene

  def activated()
    super
    transition (resume || Klondike.new), Fade, secOut: 0
  end

  private

  def resume()
    Klondike.new settings['state']
  rescue
    nil
  end

end# Start
