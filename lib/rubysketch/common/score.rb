using RubySketch


class Score

  include CanDisable

  def initialize(**definitions)
    super()
    @defs, @value = {}, 0
    define **definitions
  end

  attr_accessor :value

  def define(**definitions)
    definitions.each do |name, score|
      @defs[name.intern] = score
    end
  end

  def add(name)
    return if disabled?
    value   = @defs[name.intern]
    @value += value.to_i if value
    @value  = 0          if @value < 0
  end

  def to_h()
    {score: @value}
  end

  def load(hash)
    @value = hash['score']
  end

end# Score
