using RubySketch


class Score

  include CanDisable

  def initialize(**definitions)
    @defs, @score = {}, 0
    define **definitions
  end

  def define(**definitions)
    definitions.each do |name, score|
      @defs[name.intern] = score
    end
  end

  def add(name)
    return if disabled?
    value   = @defs[name.intern]
    @score += value.to_i if value
  end

  def revert(name)
    p [:revert, disabled?]
    return if disabled?
    value   = @defs[name.intern]
    @score -= value.to_i if value
  end

  def value()
    @score
  end

  def to_h()
    {score: @score}
  end

  def from_h(hash)
    @score = hash['score']
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
