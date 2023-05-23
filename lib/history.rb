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
      update
    end
  end

  def record(&block)
    raise if @recording
    @recording = array = []
    block.call
  ensure
    @recording = nil
    push *array
  end

  def undo(&block)
    actions = @undos.pop || return
    actions.reverse.each {|action| block.call action}
    @redos.push actions
    update
  end

  def redo(&block)
    actions = @redos.pop || return
    actions.each {|action| block.call action}
    @undos.push actions
    update
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

  def updated(&block)
    @updated = block
  end

  def to_h(&dumpObject)
    {
      version: 1,
      undos: self.class.dump(@undos, &dumpObject),
      redos: self.class.dump(@redos, &dumpObject)
    }
  end

  def self.load(hash, &restoreObject)
    undos = restore hash['undos'], &restoreObject
    redos = restore hash['redos'], &restoreObject
    self.new undos, redos
  end

  private

  def update()
    @updated.call if @updated
  end

  def self.dump(xdos, &dumpObject)
    xdos.map do |actions|
      actions.map do |action, *args|
        [action.to_s, *args.map {|obj| dumpObject.call(obj) || obj}]
      end
    end
  end

  def self.restore(xdos, &restoreObject)
    xdos.map do |actions|
      actions.map do |action, *args|
        [action.intern, *args.map {|obj| restoreObject.call(obj) || obj}]
      end
    end
  end

end# History
