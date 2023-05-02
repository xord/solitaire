$timers = {}

def startTimer(name = unique, seconds, &block)
  $timers[name] = [now + seconds, block]
end

def stopTimer(name)
  $timers.delete name
end

def getTimer(name)
  $timers[name]
end

def fireTimers()
  now_ = now
  blocks = []
  $timers.delete_if do |_, (time, block)|
    (now_ >= time).tap { blocks.push block if _1 }
  end
  blocks.each { _1.call }
end
