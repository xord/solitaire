using RubySketch


class Menu < Dialog

  def initialize()
    super
    addButton('RESUME',   width: 5) {close}
    addButton('NEW GAME', width: 5) {parent.transition Klondike.new, Fade}
  end

end# Menu
