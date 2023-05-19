class History

  def initialize()
    @undos, @redos       = [], []
    @recording, @disable = nil, false
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

  def enable()
    @disable = false
  end

  def disable(&block)
    @disable = true
    if block
      block.call
      @disable = false
    end
  end

  def disabled?()
    @disable
  end

end# History
