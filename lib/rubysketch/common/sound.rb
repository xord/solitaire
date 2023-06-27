using RubySketch


def playSound(filename, gain: 1.0)
  $sounds           ||= {}
  $sounds[filename] ||= loadSound dataPath(filename)
  $sounds[filename]&.play gain: gain * globalGain
end

def globalGain(gain = nil)
  old         = $globalGain
  $globalGain = gain if gain
  old || 1.0
end
