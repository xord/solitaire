class History

  def initialize(undos = [], redos = [])
    @undos, @redos       = undos, redos
    @recording, @enabled = nil, true
  end

  def push(*actions)
    return if disabled? || actions.empty?
    if @recording
      @recording.push *actions
    else
      @undos.push actions
      @redos.clear
    end
  end

  def record(&block)
    raise if @recording
    @recording = array = []
    block.call
    @recording = nil
    push *array
  end

  def undo(&block)
    actions = @undos.pop || return
    actions.reverse.each {|action| block.call action}
    @redos.push actions
  end

  def redo(&block)
    actions = @redos.pop || return
    actions.each {|action| block.call action}
    @undos.push actions
  end

  def canUndo?()
    !@undos.empty?
  end

  def canRedo?()
    !@redos.empty?
  end

  def enable(state = true)
    @enabled = state
  end

  def disable(&block)
    old, @enabled = @enabled, false
    if block
      block.call
      @enabled = old
    end
  end

  def enabled?()
    @enabled
  end

  def disabled?()
    !enabled?
  end

end# History
