$timers = {}

def startTimer(name = unique, seconds, &block)
  $timers[name] = [now + seconds, block]
  name
end

def startInterval(name = unique, seconds, now: false, &block)
  block.call if now
  startTimer name, seconds do
    block.call
    startInterval name, seconds, &block
  end
end

def stopTimer(name)
  $timers.delete name
end

def getTimer(name)
  $timers[name]
end

def delay(&block)
  startTimer 0, &block
end

def fireTimers()
  now_ = now
  blocks = []
  $timers.delete_if do |_, (time, block)|
    (now_ >= time).tap {|t| blocks.push block if t}
  end
  blocks.each &:call
end
