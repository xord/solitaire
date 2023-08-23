# -*- coding: utf-8 -*-
using RubySketch


class Klondike < Scene

  def initialize(hash = nil)
    super()
    hash ? load(hash) : ready
  end

  def sprites()
    super + [*cards, *places].map(&:sprite) + [ground] + interfaces
  end

  def difficulty()
    @difficulty ||= :normal
  end

  def pause()
    super
    @prevTime = nil
    clearInterval :save
  end

  def resume()
    super
    return if !started? || completed?
    @prevTime = now
    setInterval 1, id: :save, now: true do
      save
    end
  end

  def draw()
    sprite *places.map(&:sprite)
    sprite *cards.sort {|a, b| a.z <=> b.z}.map(&:sprite)
    sprite *interfaces
    super
  end

  def resized(w, h)
    super
    updateLayout w, h
  end

  def focusChanged(focus)
    focus ? resume : pause if ios?
  end

  def mouseClicked(x, y, button)
    count = 8
    count.times do |n|
      seg   = 360 / count
      angle = seg * n + rand(seg)
      len   = rand 20..30
      vec   = Vector.fromAngle(angle) * len
      emitDust createVector(x, y), vec, rand(0.2..0.5)
    end
  end

  def mouseDragged(x, y, dx, dy)
    vec = Vector.fromAngle(rand 360) * rand(20..30)
    emitDust createVector(x, y), vec, rand(0.2..0.5)
  end

  def canDrop?(card)
    case card.place
    when *columns then card.opened?
    else               card.last?
    end
  end

  def cardClicked(card)
    if card.closed? && card.place == deck
      deckClicked
    elsif card.opened? && place = findPlaceToGo(card)
      moveCard card, place, 0.3, dust: true, flash: true
    elsif card.opened?
      shake card, vector: createVector(5, 0)
      playSound 'noop.mp3', gain: 0.5
    end
  end

  def deckClicked()
    deck.empty? ? refillDeck : drawNexts
  end

  def nextsClicked()
    drawNexts if nexts.empty?
  end

  def cardDropped(x, y, card, prevPlace)
    if place = getPlaceAccepts(x, y, card)
      moveCard card, place, 0.1, dust: true
    elsif prevPlace
      history.disable do
        prevPos, prevTime = card.pos.xy, now
        moveCard card, prevPlace, 0.15, add: false, easing: :quadIn do |t, finished|
          pos, time         = card.pos.xy, now
          vel               = (pos - prevPos) / (time - prevTime)
          prevPos, prevTime = pos, time
          backToPlace card, vel if finished
        end
      end
    end
  end

  def save()
    settings['state'] = {
      version:     1,
      difficulty:  difficulty,
      history:     history.to_h {|o| o.id if o.respond_to? :id},
      score:       score.to_h,
      elapsedTime: elapsedTime,
      moveCount:   @moveCount,
      places:      places.map {|place| [place.name, place.cards.map(&:id)]}.to_h,
      openeds:     cards.select {|card| card.opened?}.map(&:id)
    }
  end

  def load(hash)
    raise 'Unknown state version' unless hash['version'] == 1

    all      = places + cards
    findAll  = -> id {  all.find {|obj|  obj .id == id} or raise "No object '#{id}'"}
    findCard = -> id {cards.find {|card| card.id == id} or raise "No card '#{id}'"}

    @difficulty = hash['difficulty'].intern

    self.history = History.load hash['history'] do |id|
      (id.respond_to?('=~') && id =~ /^id:/) ? findAll[id] : nil
    end

    self.score.load hash['score']
    @elapsedTime = hash['elapsedTime']
    @moveCount   = hash['moveCount']

    places.each do |place|
      place.clear
      ids = hash['places'][place.name.to_s] or raise "No place '#{place.name}'"
      place.add *ids.map {|id| findCard[id]}
    end

    hash['openeds'].each do |id|
      findCard[id].open
    end

    raise "Failed to restore state" unless
      places.reduce([]) {|a, place| a + place.cards}.size == 52

    start!
  end

  def inspect()
    "#<Klondike:#{object_id}>"
  end

  private

  def history()
    self.history = History.new unless @history
    @history
  end

  def history=(history)
    @history = history.tap do |h|
      h.updated {save}
    end
  end

  def elapsedTime()
    @elapsedTime ||= 0
    if @prevTime
      now_          = now
      @elapsedTime += now_ - @prevTime
      @prevTime     = now_
    end
    @elapsedTime
  end

  def score()
    @score ||= Score.new **{
      openCard:          5,
      moveToColumn:      5,
      moveToMark:        10,
      backToColumn:      -15,
      refillDeckOnDraw3: -20,
      refillDeckOnDraw1: -100
    }
  end

  def addScore(name)
    old = score.value
    score.add name if history.enabled?
    history.push [:score, score.value, old] if score.value != old
  end

  def bestTime()
    settings[bestRecordKey :time] || 24 * 60 * 60 - 1
  end

  def bestScore()
    settings[bestRecordKey :score] || 0
  end

  def dailyBestTime()
    key = bestRecordKey :time, true
    settings[key] = nil if settings["#{key}Date"] != today
    settings[key] || 24 * 60 * 60 - 1
  end

  def dailyBestScore()
    key = bestRecordKey :score, true
    settings[key] = nil if settings["#{key}Date"] != today
    settings[key] || 0
  end

  def updateBests()
    newTime       = elapsedTime < bestTime
    newScore      = score.value > bestScore
    newDailyTime  = elapsedTime < dailyBestTime
    newDailyScore = score.value > dailyBestScore

    settings[bestRecordKey :time]  = elapsedTime if newTime
    settings[bestRecordKey :score] = score.value if newScore

    if newDailyTime
      settings[bestRecordKey(:time, true)]         = elapsedTime
      settings[bestRecordKey(:time, true, 'Date')] = today
    end

    if newDailyScore
      settings[bestRecordKey(:score, true)]         = score.value
      settings[bestRecordKey(:score, true, 'Date')] = today
    end

    return newTime, newScore, newDailyTime, newDailyScore
  end

  def clearAllTimeBests()
    %i[time score]
      .map {|type| bestRecordKey type}
      .each {|key| settings[key] = nil}
  end

  def clearDailyBests()
    %i[time score]
      .map {|type| ['', 'Date'].map {|s| bestRecordKey type, true, s}}
      .flatten
      .each {|key| settings[key] = nil}
  end

  def bestRecordKey(type, daily = false, suffix = '')
    difficulty.to_s +
      (daily ? 'Daily' : '') +
      'Best' +
      type.to_s.capitalize +
      suffix
  end

  def timeToText(time)
    Time.at(time).strftime('%M:%S')
  end

  def today()
    Time.now.strftime '%Y%m%d'
  end

  def cards()
    @cards ||= Card::MARKS.product((1..13).to_a)
      .map {|m, n| Card.new self, m, n}
      .each {|card| card.sprite.mouseClicked {cardClicked card}}
  end

  def places()
    @places ||= [deck, nexts, *marks, *columns]
  end

  def deck()
    @deck ||= CardPlace.new(self, :deck).tap do |deck|
      deck.sprite.mouseClicked {deckClicked}
    end
  end

  def nexts()
    @nexts ||= NextsPlace.new(self, :nexts).tap do |nexts|
      nexts.sprite.mouseClicked {nextsClicked}
    end
  end

  def marks()
    @marks ||= Card::MARKS.size.times.map {|i| MarkPlace.new self, "mark_#{i + 1}"}
  end

  def columns()
    @culumns ||= 7.times.map.with_index {|i| ColumnPlace.new self, "column_#{i + 1}"}
  end

  def ground()
    @ground ||= createSprite 0, 0, 1, 10
  end

  def interfaces()
    [undoButton, redoButton, pauseButton, finishButton, status, debugButton]
  end

  def undoButton()
    @undoButton ||= Button.new(
      '◀', fontSize: 28, round: [20, 4, 4, 20]
    ).tap do |b|
      b.update  {b.enable history.canUndo?}
      b.clicked {history.undo {|action| undo action}}
    end
  end

  def redoButton()
    @redoButton ||= Button.new(
      '▶', fontSize: 28, round: [4, 20, 20, 4]
    ).tap do |b|
      b.update  {b.enable history.canRedo?}
      b.clicked {history.redo {|action| self.redo action}}
    end
  end

  def pauseButton()
    @pauseButton ||= Button.new(icon: skin.pauseIcon).tap do |b|
      b.clicked {showPauseDialog}
    end
  end

  def status()
    @status ||= Sprite.new.tap do |sp|
      sp.draw do
        push do
          fill *skin.translucentBackgroundColor
          rect 0, 0, sp.w, sp.h, 10
          fill 255

          mx, my, x, w = 8, 4, 0, sp.w / 3
          {
            Time:  timeToText(elapsedTime),
            Score: score.value,
            Move:  @moveCount || 0
          }.each do |label, value|
            textSize 12
            textAlign LEFT, TOP
            text str(label), x + mx, my, w - mx, sp.h - my * 2
            textSize 20
            textAlign LEFT, BOTTOM
            text value, x + mx, my, w - mx, sp.h - my * 2
            x += w
          end
        end
      end
    end
  end

  def finishButton()
    @finishButton ||= Button.new(
      'FINISH!', rgb: [100, 200, 150], fontSize: 28, width: 5
    ).tap do |b|
      b.hide
      b.clicked {finish!}
    end
  end

  def debugButton()
    @debugButton ||= Button.new(:DEBUG, width: 3).tap do |b|
      b.hide unless debug?
      b.clicked {showDebugDialog}
    end
  end

  def showReadyDialog()
    add Dialog.new(alpha: 50).tap {|d|
      d.addButton str('EASY'), width: 5 do
        start :easy
        d.close
      end
      d.addButton str('NORMAL'), width: 5 do
        start :normal
        d.close
      end
      d.addButton str('HARD'), width: 5 do
        start :hard
        d.close
      end
    }
  end

  def showPauseDialog()
    add Dialog.new {|d|
      d.addLabel "#{str 'Difficulty'}: #{str difficulty.upcase}"
      d.addLabel "#{str 'Best Time'}: #{timeToText bestTime}"
      d.addLabel "#{str 'Best Score'}: #{bestScore}"
      d.addLabel "#{str "Today's Best Time"}: #{timeToText dailyBestTime}"
      d.addLabel "#{str "Today's Best Score"}: #{dailyBestScore}"
      d.addSpace 20
      d.addButton str('Resume'), width: 6 do
        d.close
      end
      d.addButton str('New Game'), width: 6 do
        d.close
        showNewGameDialog
      end
      d.addSpace 10
      d.group do
        if ios?
          d.addButton icon: skin.menuIcon do
            sendCommand :showMenu
          end
        end
        d.addButton icon: skin.settingsIcon do
          showSettingsDialog
        end
      end
    }
  end

  def showNewGameDialog()
    add Dialog.new(alpha: 180).tap {|d|
      d.addLabel str("Start New Game?")
      d.addSpace 20
      d.addButton str('OK'), width: 4 do
        d.close
        startNewGame
      end
      d.addButton str('Cancel'), width: 4 do
        d.close
      end
    }
  end

  def showSettingsDialog()
    closedImage = -> {
      i = skin.closedImage
      resizeImage i, i.width / 2, i.height / 2
    }
    add Dialog.new(alpha: 255).tap {|d|
      bg        = d.add Background.new backgroundScene.type
      cardImage = d.addElement Sprite.new image: closedImage.call
      d.addButton str('Change Card Design'), width: 7 do
        skin skin.index + 1
        settings['skinIndex'] = skin.index
        cardImage.image = closedImage.call
      end
      d.addSpace 10
      author = -> {bg.author&.then {|author| "by #{author}"} || '-'}
      bgName = bgAuthor = nil
      d.group :vertical, space: 0 do
        bgName   = d.addLabel(bg.name, fontSize: 24, alpha: 0) {sendCommand :openURL, bg.url}
        bgAuthor = d.addLabel author.call, fontSize: 16, alpha: 0
      end
      d.addButton str('Change Background'), width: 7 do
        bg.set bg.nextType
        bgName  .label = bg.name
        bgAuthor.label = author.call
        backgroundScene.set bg.type
      end
      d.addSpace 20
      d.addCheck str('Particle & Visual Effect'), checked: vfx? do |checked|
        settings['vfx'] = checked
      end
      d.addSpace 20
      d.addButton str('Close'), width: 6 do
        d.close
      end
    }
  end

  def showCompletedDialog(
         bestTime = false,      bestScore = false,
    dailyBestTime = false, dailyBestScore = false)

    suffix = -> allTime, daily do
      return str '(New Record!)'   if allTime
      return str "(Today's Best!)" if daily
      ''
    end

    add Dialog.new.tap {|d|
      d.addLabel str('Congratulations!'), fontSize: 36
      d.addLabel(
        "#{str 'Time'}: #{timeToText elapsedTime} #{suffix.call bestTime, dailyBestTime}",
        fontSize: 22)
      d.addLabel(
        "#{str 'Score'}: #{score.value} #{suffix.call bestScore, dailyBestScore}",
        fontSize: 22)
      d.addSpace 50
      d.addButton str('Start Next Game'), width: 5 do
        d.close
        startNewGame true
      end
    }
  end

  def showDebugDialog()
    add Dialog.new.tap {|d|
      d.addButton str('Clear all settings'), width: 6 do
        settings.clear
        d.close
      end
      d.addButton str('Clear all time bests'), width: 6 do
        clearAllTimeBests
        d.close
      end
      d.addButton str("Clear today's bests"), width: 6 do
        clearDailyBests
        d.close
      end
      d.addButton str("One step for completion"), width: 6 do
        cards.sort.group_by(&:mark).each.with_index do |(mark, cards_), index|
          place = marks[index]
          place.clear
          place.add *cards_.each {_1.open}
        end
        d.close
      end
      d.addButton str("Dump settings"), width: 6 do
        puts settings.to_json
        d.close
      end
      d.addButton str('Close'), width: 6 do
        d.close
      end
    }
  end

  def updateLayout(w, h)
    card   = cards.first
    cw, ch = card.then {|c| [c.w, c.h]}
    mx, my = skin.margin, cw * 0.2 # margin x, y
    y      = my

    undoButton.pos  = [mx, y]
    redoButton.pos  = [undoButton.x + undoButton.w + 2, y]
    pauseButton.pos = [width - (pauseButton.w + mx), y]
    status.pos      = [redoButton.right + mx, y]
    status.right    = pauseButton.left - mx
    status.height   = pauseButton.h

    y = undoButton.y + undoButton.h + my * 3

    deck.pos  = [w - (deck.w + mx), y]
    nexts.pos = [deck.x - (nexts.w + mx), deck.y]
    marks.each.with_index do |mark, index|
      mark.pos = [mx + (mark.w + mx) * index, deck.y]
    end

    y = deck.y + deck.h + my

    columns.each.with_index do |column, index|
      s = columns.size
      m = (w - cw * s) / (s + 1) # margin
      column.pos = [m + (cw + m) * index, y]
    end

    ground.y = height + ch + 5
    ground.w = width

    places.each {|place| place.updateCards}

    debugButton.pos = [mx, height - (debugButton.h + my)]
  end

  def ready()
    elements = showReadyDialog.elements
    elements.each &:hide

    history.disable
    deck.add *cards.shuffle
    setTimeout 0.5 do
      placeToColumns do
        history.enable
        elements.each &:show
      end
    end
  end

  def start(difficulty = :normal)
    @difficulty = difficulty
    start!

    history.disable
    lasts = columns.map(&:last).compact
    lasts.each.with_index do |card, n|
      setTimeout 0.02 * n do
        openCard card, gain: 0.2
        if lasts.all? {|card| card.opened?}
          drawNexts
          history.enable
        end
      end
    end
  end

  def placeToColumns(&block)
    firstDistribution.then do |positions|
      positions.each.with_index do |(col, row), index|
        setTimeout index / 25.0 do
          playSound 'flip.mp3', gain: 0.1
          moveCard deck.last, columns[col], 0.5, hover: false do |t, finished|
            block&.call if finished && [col, row] == positions.last
          end
        end
      end
    end
  end

  def firstDistribution()
    n = columns.size
    (0...n).map {|row| (row...n).map {|col| [col, row]}}.flatten(1)
  end

  def openCard(card, gain: 0.5)
    return if card.opened?
    history.group do
      card.open 0.3
      history.push [:open, card]
      addScore :openCard if columns.include?(card.place)
    end
    playSound 'flip.mp3', gain: gain
  end

  def closeCard(card)
    return if card.closed?
    card.close 0.3
    history.push [:close, card]
  end

  def moveCard(
    card, toPlace, seconds = 0,
    from: card.place, add: true, count: true, hover: true,
    dust: false, flash: false,
    **kwargs, &block)

    pos = toPlace.posFor card
    card.hover base: pos.z if hover
    toPlace.add card, updatePos: false if add
    move card, pos, seconds, **kwargs do |t, finished|
      emitDustOnEdges card if finished && dust
      flashCard card       if finished && flash
      block.call t, finished if block
      cardMoved from if finished
    end

    playSound "deal#{(1..3).to_a.sample}.mp3"

    @moveCount ||= 0
    @moveCount  += 1 if count && history.enabled?

    history.group do
      history.push [:move, card, from, toPlace]
      history.push [:moveCount, @moveCount]

      fromNexts  = from == nexts
      fromColumn = columns.include? from
        toColumn = columns.include? toPlace
      fromMark   = marks.include? from
        toMark   = marks.include? toPlace
      addScore :moveToColumn if fromNexts && toColumn
      addScore :backToColumn if fromMark  && toColumn
      addScore :moveToMark   if !fromMark && toMark

      openCard from.last if fromColumn && from.last&.closed?
    end
  end

  def cardMoved(from)
    openCard from.last if columns.include?(from) && from.last&.closed?
    showFinishButton   if finishButton.hidden? && canFinish?
    completed!         if completed?
  end

  def flashCard(card)
    return unless vfx?
    card.flash
    setTimeout(0.01) {flashCard card.next} if card.next
  end

  def start!()
    @started = true
    [*cards, *places].each do |o|
      o.started if o.respond_to? :started
    end
    places.each {|p| p.updateCards 0}
    resume
  end

  def started?()
    @started ||= false
  end

  def canFinish?()
    deck.empty? && nexts.empty? &&
      columns.any? {|col| !col.empty?} &&
      columns.all? {|col| col.each_cons(2).all? {|a, b| a.number > b.number}}
  end

  def completed?()
    deck.empty? && nexts.empty? && columns.all?(&:empty?)
  end

  def drawNexts()
    return if deck.empty?
    history.group do
      cards = nexts.drawCount.times.map {deck.pop}.compact
      nexts.add *cards, updatePos: false
      cards.each.with_index do |card, index|
        openCard card
        moveCard card, nexts, 0.3, from: deck, add: false, count: index == 0
      end
    end
  end

  def refillDeck()
    history.group do
      gain = globalGain 0.2
      nexts.cards.reverse.each.with_index do |card, index|
        closeCard card
        moveCard card, deck, 0.3, count: index == 0
      end
      globalGain gain
      incrementRefillCount
    end
    #setTimeout(0.4) {drawNexts}
  end

  def incrementRefillCount()
    @refillCount ||= 0
    @refillCount  += 1
    case nexts.drawCount
    when 1 then addScore :refillDeckOnDraw1
    when 3 then addScore :refillDeckOnDraw3 if @refillCount >= 3
    end
  end

  def getPlaceAccepts(x, y, card)
    (columns + marks).find {|place| place.accept? x, y, card}
  end

  def findPlaceToGo(card)
    return nil if marks.include?(card.place)
    marks.find {|place| place.accept? *place.center.to_a(2), card} ||
      columns.shuffle.find {|place| place.accept? *place.center.to_a(2), card}
  end

  def showFinishButton()
    finishButton.tap do |b|
      m   = skin.margin
      b.x = marks.last.then {|mark| mark.x + mark.w} + m * 2
      b.y = -deck.h
      b.w = width - b.x - m
      b.h = deck.h
    end
    pos   = finishButton.pos.dup
    pos.y = deck.y
    move finishButton.show, pos, 1, easing: :bounceOut
  end

  def finish!(cards = columns.map(&:cards).flatten.sort)
    card  = cards.shift or return
    place = marks.find {|mark| mark.accept? mark.x, mark.y, card} or return
    moveCard card, place, 0.3, dust: true, flash: true
    setTimeout(0.05) {finish! cards}
  end

  def completed!()
    return if @completed
    @completed = true

    history.disable
    showCompletedDialog *updateBests

    gravity 0, 1000

    cards.group_by(&:number).values
      .reverse
      .map(&:shuffle)
      .flatten
      .each.with_index do |card, index|

      setTimeout 0.1 * index do
        card.place&.pop
        card.sprite.tap do |sp|
          sp.fixAngle
          sp.contact? {|o| o == ground}
          bounce = 0
          sp.contact {|_, action|
            next unless action == :begin
            bounce += 1
            if bounce > 3
              sp.dynamic = false
              sp.hide
            else
              vec = Vector.fromAngle(rand -135..-45) * rand(75..100)
              emitDust sp.center, vec, size: 10..20
            end
          }
          sp.dynamic     = true
          sp.restitution = 0.5
          sp.vx          = rand -20..100
          sp.vy          = -300
        end
      end
    end
  end

  def backToPlace(card, vel)
    return if vel.mag == 0
    vec = vel.dup.normalize * sqrt(vel.mag) / 10 * sqrt(card.count)
    shakeScreen vector: vec
    emitDustOnEdges card, size: sqrt(vec.mag).then {|m| m..(m * 5)}
  end

  def emitDustOnEdges(card, amount = 10, speed: 10, **kwargs)
    amount.times {
      pos = createVector *randomEdge(card)
      vec = (pos - card.center).normalize * speed
      emitDust pos, vec, **kwargs
    }
  end

  def emitDust(pos, vec, sec = 0.5, size: 2.0..10.0, rgb: nil)
    return unless vfx?
    size_   = rand size
    par     = emitParticle pos.x, pos.y, size_, size_, sec
    par.rgb = rgb || 3.times.map {rand 100..200}
    animateValue(sec, from: pos, to: pos + vec)           {|p| par.pos   = p}
    animateValue(sec, from: 255, to: 0, easing: :sineOut) {|a| par.alpha = a}
  end

  def randomEdge(card)
    if rand < card.w / (card.w + card.h)
      [
        card.x + rand(card.w),
        card.y + (rand < 0.5 ? 0 : card.h)
      ]
    else
      [
        card.x + (rand < 0.5 ? 0 : card.w),
        card.y + rand(card.h)
      ]
    end
  end

  def undo(action)
    history.disable do
      case action
      in [:open,  card]           then closeCard card
      in [:close, card]           then  openCard card
      in [:move,  card, from, to] then moveCard card, from, 0.2, from: to
      in [:score,     value, old] then score.value = old
      in [:moveCount, value]      then @moveCount  = value - 1
      end
    end
  end

  def redo(action)
    history.disable do
      case action
      in [:open,  card]           then  openCard card
      in [:close, card]           then closeCard card
      in [:move,  card, from, to] then moveCard card, to, 0.2, from: from
      in [:score,     value, old] then score.value = value
      in [:moveCount, value]      then @moveCount  = value
      end
    end
  end

  def startNewGame(completed = false)
    $newGameCount ||= 0
    $newGameCount  += 1
    completeCount increment: true if completed && difficulty != :easy

    cc = completeCount
    requestReview = cc == 1 && cc != lastCompleteCountForRequestReview
    lastCompleteCountForRequestReview update: cc if requestReview

    transition(
      self.class.new,
      [Fade, Curtain, Pixelate].sample,
      showAd:        $newGameCount % 3 == 0,
      requestReview: requestReview)
  end

  def completeCount(increment = false)
    key = __method__.to_s
    if increment
      settings[key] ||= 0
      settings[key]  += 1
    end
    settings[key] || 0
  end

  def lastCompleteCountForRequestReview(update: nil)
    key = __method__.to_s
    settings[key] = update if update
    settings[key]
  end

  def vfx?(update: nil)
    key = 'vfx'
    settings[key]  = update if update != nil
    settings[key].then {_1 == nil || _1 == true}
  end

  STRINGS = {
    OK:     {},
    Cancel: {ja: 'キャンセル'},
    Close:  {ja: '閉じる'},

    Time:  {ja: 'タイム'},
    Score: {ja: 'スコア'},
    Move:  {ja: '移動回数'},

    Difficulty: {ja: '難易度'},
    EASY:       {ja: '簡単'},
    NORMAL:     {ja: '普通'},
    HARD:       {ja: '難しい'},

    'New Game': {ja: '新規ゲーム'},
    'Resume': {ja: 'ゲーム再開'},

    'Best Time':          {ja: 'ベストタイム'},
    'Best Score':         {ja: 'ベストスコア'},
    "Today's Best Time":  {ja: '本日のベストタイム'},
    "Today's Best Score": {ja: '本日のベストスコア'},

    "Start New Game?": {ja: '新しいゲームをはじめますか？'},
    "Start Next Game": {ja: '次のゲームを開始'},

    "Change Card Design": {ja: 'カードデザインを変更'},
    "Change Background":  {ja: 'ゲーム背景を変更'},
    "Particle & Visual Effect": {ja: 'パーティクルと視覚効果'},

    '(New Record!)':   {ja: '（新記録！）'},
    "(Today's Best!)": {ja: '（本日のベスト！）'},
  }

  def str(s, lang: $language)
    STRINGS.dig(s.intern, lang&.intern) || s.to_s
  end

end# Klondike


class Klondike::NextsPlace < CardPlace

  def drawCount()
    @game.difficulty == :hard ? 3 : 1
  end

  def started()
    w       = skin.cardSpriteSize[0] + overlap * (drawCount - 1)
    self.x -= w - self.w
    self.w  = w
  end

  def add(*cards, **kwargs)
    super
    updateCards excludes: cards
  end

  def pop(*args)
    super
    updateCards
  end

  def posFor(card, index = nil)
    index ||= indexFor card
    super.tap do |pos|
      rindex = cards.size - index
      pos.x += overlap * (drawCount - rindex).clamp(0, drawCount - 1)
    end
  end

  def overlap()
    skin.cardSpriteSize[0] * 0.4
  end

end# Klondike::NextsPlace


class Klondike::MarkPlace < CardPlace

  def mark()
    last&.mark
  end

  def accept?(x, y, card)
    return false if !card || card.closed? || !card.canDrop?
    hit?(x, y) &&
      card.last? &&
      card.opened? &&
      (!mark || mark == card.mark) &&
      card.number == last&.number.then {|n| n ? n + 1 : 1}
  end

end# Klondike::MarkPlace


class Klondike::ColumnPlace < CardPlace

  def initialize(*args, **kwargs, &block)
    super(*args, linkCards: true, **kwargs, &block)
  end

  def accept?(x, y, card)
    return false if !card || card.closed? || !card.canDrop?
    if empty?
      hit?(x, y) &&
        card.number == 13
    else
      any? {|card| card.hit?(x, y)} &&
        card.number == last.number - 1 &&
        (@game.difficulty == :easy || card.color != last.color)
    end
  end

  def posFor(card, index = nil)
    index ||= indexFor card
    super.tap do |pos|
      pos.y += self.h * 0.3 * index
    end
  end

end# Klondike::ColumnPlace
