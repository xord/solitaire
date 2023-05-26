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

  def from_h(hash)
    @value = hash['score']
  end

end# Score


class HighScores

  def record(type, score)
    scores[type.intern] = score if score > get(type)
  end

  def get(type)
    scores[type.intern]&.to_i || 0
  end

  def save(path = SCORES_PATH)
    File.write path, @scores.to_json
  end

  def self.load(path = SCORES_PATH)
    @scores = JSON.parse File.read path
  end

  private

  def scores()
    @scores ||= {}
  end

end# HighScores
