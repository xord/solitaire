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
      prevPos = card.pos
      history.disable do
        moveCard card, prevPlace, 0.15, ease: :quadIn do |t, finished|
          backToPlace card, prevPos if finished
          prevPos = card.pos.dup
        end
      end
    end
  end

  def save(path = 'state.json')
    File.write path, {
      version: 1,
      game: self.class.name,
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
    @nexts ||= CardPlace.new(:nexts).tap do |nexts|
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
    [undoButton, redoButton, menuButton, debugButton]
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

  def debugButton()
    @debugButton ||= Button.new(:DEBUG, width: 3).tap do |b|
      b.clicked {start}
    end
  end

  def updateLayout(w, h)
    card      = cards.first
    cw, ch    = card.then {|c| [c.w, c.h]}
    margin    = cw * 0.2
    y         = margin

    undoButton.pos = [margin, y]
    redoButton.pos = [undoButton.x + undoButton.w + 2, y]
    menuButton.pos = [width - (menuButton.w + margin), y]

    y = undoButton.y + undoButton.h + margin

    deck.pos  = [w - (cw + margin), y]
    nexts.pos = [deck.x - (cw + margin), deck.y]
    marks.each.with_index do |mark, index|
      mark.pos = [margin + (cw + margin) * index, deck.y]
    end

    y = deck.y + deck.h + margin

    columns.each.with_index do |column, index|
      s = columns.size
      m = (w - cw * s) / (s + 1) # margin
      column.pos = [m + (cw + m) * index, y]
    end

    debugButton.pos = [margin, height - (debugButton.h + margin)]
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
    card, toPlace, seconds = 0, from: card.place, hover: true,
    **kwargs, &block)

    card.place&.pop card if card.place

    pos    = toPlace.posFor card
    card.z = pos.z + (hover ? 100 : 0)
    toPlace.add card, updatePos: false
    move card, pos, seconds, **kwargs, &block

    history.push [:move, card, from, toPlace]
  end

  def openNexts(count = 1)
    return if deck.empty?
    history.record do
      card = deck.last
      openCard card
      moveCard card, nexts, 0.3
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
  end

  def getPlaceAccepts(x, y, card)
    (columns + marks).find {|place| place.accept? x, y, card}
  end

  def getPlaceToGo(card)
    marks.find {|place| place.accept? *place.center.to_a(2), card} ||
      columns.shuffle.find {|place| place.accept? *place.center.to_a(2), card}
  end

  def backToPlace(card, prevPos)
    vel = card.pos - prevPos
    return if vel.mag < 3
    shake vector: vel / 10 * card.count
    10.times {
      x, y = randomEdge card
      size = rand(2.0..10.0)
      pos  = createVector x, y
      vec  = (pos - card.center).normalize * 10
      sec  = 0.5
      par  = emitParticle x, y, size, size, sec
      animate sec do |t|
        par.pos   = pos + vec * t
        par.alpha = (1.0 - t) * 255
      end
    }
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
