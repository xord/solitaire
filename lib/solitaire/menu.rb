using RubySketch


class Menu < Dialog

  def initialize()
    super

    addButton 'RESUME', width: 5 do
      close
    end

    addButton 'NEW GAME', width: 5 do
      parent.transition Klondike.new, Fade
    end
  end

end# Menu
