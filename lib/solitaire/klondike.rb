# -*- coding: utf-8 -*-
using RubySketch


class Klondike < Scene

  def initialize(hash = nil)
    super()
    @sprites = [*cards, *places].map &:sprite
    hash ? load(hash) : ready
  end

  def sprites()
    super + @sprites + buttons
  end

  def draw()
    sprite *places.map(&:sprite)
    sprite *cards.sort {|a, b| a.z <=> b.z}.map(&:sprite)
    sprite *buttons
    super
  end

  def resized(w, h)
    super
    updateLayout w, h
  end

  def canDrop?(card)
    case card.place
    when *columns then card.opened?
    else               card.last?
    end
  end

  def cardClicked(card)
    if newPlace = getPlaceToGo(card)
      moveCard card, newPlace, 0.3
    else
      case card.place
      when deck     then deckClicked
      when nexts    then nextsClicked
      when *columns then openCard card if card.closed? && card.last?
      end
    end
  end

  def deckClicked()
    deck.empty? ? refillDeck : openNexts
  end

  def nextsClicked()
    openNexts if nexts.empty?
  end

  def cardDropped(x, y, card, prevPlace)
    if place = getPlaceAccepts(x, y, card)
      moveCard card, place, 0.2
    elsif prevPlace
      history.disable do
        prevPos, prevTime = card.pos.xy, now
        moveCard card, prevPlace, 0.15, add: false, ease: :quadIn do |t, finished|
          pos, time         = card.pos.xy, now
          vel               = (pos - prevPos) / (time - prevTime)
          prevPos, prevTime = pos, time
          backToPlace card, vel if finished
        end
      end
    end
  end

  def save(path = 'state.json')
    File.write path, {
      version: 1,
      game: self.class.name,
      openCount: nexts.openCount,
      history: history.to_h {|o| o.id if o.respond_to? :id},
      places: places.map {|place| [place.name, place.cards.map(&:id)]}.to_h,
      openeds: cards.select {|card| card.opened?}.map(&:id)
    }.to_json
  rescue
    nil
  end

  def self.load(path = 'state.json')
    self.new JSON.parse File.read path
  end

  def load(hash)
    raise 'Unknown state version' unless hash['version'] == 1

    all      = places + cards
    findAll  = -> id {  all.find {|obj|  obj .id == id} or raise "No object '#{id}'"}
    findCard = -> id {cards.find {|card| card.id == id} or raise "No card '#{id}'"}

    nexts.openCount = hash['openCount']

    self.history = History.load hash['history'] do |id|
      (id =~ /^id:/) ? findAll[id] : nil
    end
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

  def cards()
    @cards ||= Card::MARKS.product((1..13).to_a)
      .map {|m, n| Card.new self, m, n}
      .each {|card| card.sprite.mouseClicked {cardClicked card}}
  end

  def places()
    @places ||= [deck, nexts, *marks, *columns]
  end

  def deck()
    @deck ||= CardPlace.new(:deck).tap do |deck|
      deck.sprite.mouseClicked {deckClicked}
    end
  end

  def nexts()
    @nexts ||= NextsPlace.new(:nexts).tap do |nexts|
      nexts.sprite.mouseClicked {nextsClicked}
    end
  end

  def marks()
    @marks ||= Card::MARKS.size.times.map {|i| MarkPlace.new "mark_#{i + 1}"}
  end

  def columns()
    @culumns ||= 7.times.map.with_index {|i| ColumnPlace.new "column_#{i + 1}"}
  end

  def buttons()
    [undoButton, redoButton, menuButton, finishButton, debugButton]
  end

  def undoButton()
    @undoButton ||= Button.new(
      '◀', rgb: [120, 140, 160], fontSize: 28, round: [20, 4, 4, 20]
    ).tap do |b|
      b.update  {b.enable history.canUndo?}
      b.clicked {history.undo {|action| undo action}}
    end
  end

  def redoButton()
    @redoButton ||= Button.new(
      '▶', rgb: [160, 140, 120], fontSize: 28, round: [4, 20, 20, 4]
    ).tap do |b|
      b.update  {b.enable history.canRedo?}
      b.clicked {history.redo {|action| self.redo action}}
    end
  end

  def menuButton()
    @menuButton ||= Button.new(
      '≡', rgb: [140, 160, 120], fontSize: 36
    ).tap do |b|
      b.clicked {add Menu.new}
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
      b.clicked {start}
    end
  end

  def updateLayout(w, h)
    card   = cards.first
    cw, ch = card.then {|c| [c.w, c.h]}
    mx, my = Card.margin, cw * 0.2 # margin x, y
    y      = my

    undoButton.pos = [mx, y]
    redoButton.pos = [undoButton.x + undoButton.w + 2, y]
    menuButton.pos = [width - (menuButton.w + mx), y]

    y = undoButton.y + undoButton.h + my

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

    debugButton.pos = [mx, height - (debugButton.h + my)]
  end

  def ready()
    showReadyDialog

    history.disable
    deck.add *cards.shuffle
    startTimer 0.3 do
      placeToColumns do
        history.enable
      end
    end
  end

  def showReadyDialog()
    add Dialog.new(alpha: 50).tap {|d|
      d.addButton 'EASY', width: 5 do
        start 1
        d.close
      end
      d.addButton 'HARD', width: 5 do
        start 3
        d.close
      end
    }
  end

  def start(openCount = 1)
    nexts.openCount = openCount

    history.disable
    lasts = columns.map(&:last).compact
    lasts.each.with_index do |card, n|
      startTimer 0.02 * n do
        openCard card
        if lasts.all? {|card| card.opened?}
          openNexts
          history.enable
          save
        end
      end
    end
  end

  def placeToColumns(&block)
    firstDistribution.then do |positions|
      positions.each.with_index do |(col, row), index|
        startTimer index / 50.0 do
          moveCard deck.last, columns[col], 0.5, hover: false do |t, finished|
            block&.call if finished && [col, row] == positions.last
          end
        end
      end
    end
  end

  def firstDistribution()
    n = columns.size
    (0...n).map { |row| (row...n).map { |col| [col, row] } }.flatten(1)
  end

  def openCard(card)
    return if card.opened?
    card.open 0.3
    history.push [:open, card]
  end

  def closeCard(card)
    return if card.closed?
    card.close 0.3
    history.push [:close, card]
  end

  def moveCard(
    card, toPlace, seconds = 0, from: card.place, add: true, hover: true,
    **kwargs, &block)

    pos = toPlace.posFor card
    card.hover base: pos.z if hover
    toPlace.add card, updatePos: false if add
    move card, pos, seconds, **kwargs do |t, finished|
      block.call t, finished if block
      openCard from.last if finished && columns.include?(from) && from.last&.closed?
      afterMovingCard if finished
    end

    history.push [:move, card, from, toPlace]
  end

  def openNexts()
    return if deck.empty?
    history.record do
      cards = nexts.openCount.times.map {deck.pop}.compact
      nexts.add *cards, updatePos: false
      cards.each do |card|
        openCard card
        moveCard card, nexts, 0.3, from: deck, add: false
      end
    end
  end

  def refillDeck()
    history.record do
      until nexts.empty?
        card = nexts.last
        closeCard card
        moveCard card, deck, 0.3
      end
    end
    startTimer(0.4) {openNexts}
  end

  def getPlaceAccepts(x, y, card)
    (columns + marks).find {|place| place.accept? x, y, card}
  end

  def getPlaceToGo(card)
    marks.find {|place| place.accept? *place.center.to_a(2), card} ||
      columns.shuffle.find {|place| place.accept? *place.center.to_a(2), card}
  end

  def afterMovingCard()
    case
    when deck.empty? && nexts.empty? && columns.all?(&:empty?)
      completed
    when finishButton.hidden? && canFinish?
      showFinishButton
    end
  end

  def canFinish?()
    deck.empty? && nexts.empty? &&
      columns.any? {|col| !col.empty?} &&
      columns.all? {|col| col.each_cons(2).all? {|a, b| a.number > b.number}}
  end

  def showFinishButton()
    finishButton.tap do |b|
      m   = Card.margin
      b.x = marks.last.then {|mark| mark.x + mark.w} + m * 2
      b.y = -deck.h
      b.w = width - b.x - m
      b.h = deck.h
    end
    pos = finishButton.pos.dup
    pos.y = deck.y
    move finishButton.show, pos, 1, ease: :bounceOut
  end

  def finish!(cards = columns.map(&:cards).flatten.sort)
    card  = cards.shift or return
    place = marks.find {|mark| mark.accept? mark.x, mark.y, card} or return
    moveCard card, place, 0.3
    startTimer(0.05) {finish! cards}
  end

  def completed()
    history.disable

    gravity 0, 1000
    ground = createSprite(0, height + cards.first.height + 5, width, 10).tap do |sp|
      sp.dynamic = false
    end

    cards.group_by(&:number).values
      .reverse
      .map(&:shuffle)
      .flatten
      .each.with_index do |card, index|

      startTimer 0.1 * index do
        card.place&.pop
        card.sprite.tap do |sp|
          sp.contact? {|o| o == ground}
          sp.contact {
            vec = Vector.fromAngle(rand -135..-45) * rand(75..100)
            emitDust sp.center, vec, size: 10..20
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
    vec = vel.dup.normalize * sqrt(vel.mag) / 10 * sqrt(card.count)
    return if vec.mag < 3
    shake vector: vec
    emitDustOnEdges card, size: sqrt(vec.mag).then {|m| m..(m * 5)}
  end

  def emitDustOnEdges(card, amount = 10, speed: 10, **kwargs)
    amount.times {
      pos = createVector *randomEdge(card)
      vec = (pos - card.center).normalize * speed
      emitDust pos, vec, **kwargs
    }
  end

  def emitDust(pos, vec, sec = 0.5, size: 2.0..10.0)
    size_ = rand size
    par   = emitParticle pos.x, pos.y, size_, size_, sec
    animateValue(sec, from: pos, to: pos + vec) {|p| par.pos   = p}
    animateValue(sec, from: 255, to: 0)         {|a| par.alpha = a}
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
      end
    end
  end

  def redo(action)
    history.disable do
      case action
      in [:open,  card]           then  openCard card
      in [:close, card]           then closeCard card
      in [:move,  card, from, to] then moveCard card, to, 0.2, from: from
      end
    end
  end

end# Klondike
