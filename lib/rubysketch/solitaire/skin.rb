using RubySketch


class Skin

  def self.setup()
    ncolumns         = 7
    size             = [width, height].min
    @margin          = size * 0.02
    @cardSpriteWidth = (size - @margin * (ncolumns + 1)) / ncolumns
  end

  def initialize(index = 0)
    @index = index % self.class.offsets.size
  end

  attr_reader :index

  def pauseIcon()
    @pauseIcon ||= self.class.getAssetImage 0, 192, 64, 64
  end

  def settingsIcon()
    @settingsIcon ||= self.class.getAssetImage 64, 192, 64, 64
  end

  def closedImage()
    @closedImage ||= self.class.closedImages[index]
  end

  def openedImage(mark, number)
    (@openedImages ||= {})[[mark, number]] ||= createOpenedImage mark, number
  end

  def cardSpriteSize()
    @cardSpriteSize ||= self.class.cardSpriteSize
  end

  def backgroundCheckerColors()
    @backgroundColors ||= self.class.colors[index][0, 2]
  end

  def redColor()
    @redColor ||= self.class.colors[index][2]
  end

  def blackColor()
    @blackColor ||= self.class.colors[index][3]
  end

  def buttonColor()
    @buttonColor ||= self.class.colors[index][4]
  end

  def translucentBackgroundColor()
    [0, 0, 0, 64]
  end

  def margin()
    self.class.margin
  end

  def markColor(mark)
    Card::MARKS[0, 2].include?(mark) ? redColor : blackColor
  end

  private

  def createOpenedImage(mark, number)
    c = self.class
    createGraphics(*c.cardImageSize).tap do |g|
      w, h, m        = g.width, g.height, 16# margin
      image          = c.assetImage
      nx, ny, nw, nh = c.numberRect number
      mx, my, mw, mh = c.markRect mark
      mnh            = m + nh
      mxx, myy       = (w - mw) / 2, mnh + ((h - mnh) - mh) / 2
      g.beginDraw do
        g.angleMode DEGREES
        g.translate  w / 2,  h / 2
        g.rotate 180
        g.translate -w / 2, -h / 2
        g.copy image, 896,  0, w,  h,  0,   0,   w,  h
        g.tint *markColor(mark)
        g.copy image, nx, ny,  nw, nh, m,   m,   nw, nh
        g.copy image, mx, my,  mw, mh, mxx, myy, mw, mh
      end
    end
  end

  def self.assetImage()
    @assetImage ||= loadImage dataPath 'card.png'
  end

  def self.margin()
    @margin
  end

  def self.markRect(mark)
    w = h = 128
    [Card::MARKS.index(mark) * w, 0, w, h]
  end

  def self.numberRect(number)
    w = h = 64
    [(number - 1) * w, 128, w, h]
  end

  def self.closedImages()
    @closedImages ||= offsets.map do |x|
      getAssetImage x, 256, *cardImageSize
    end
  end

  def self.getAssetImage(x, y, w, h)
    createGraphics(w, h).tap do |g|
      g.beginDraw do
        w, h = g.width, g.height
        g.copy assetImage, x, y, w, h, 0, 0, w, h
      end
    end
  end

  def self.colors()
    @colors ||= offsets.map do |x|
      5.times
        .map {|n| [x + n * 48 + 10, 512 + 10]}
        .map {|xx, yy| assetImage.get xx, yy}
        .map {|c| [red(c), green(c), blue(c), alpha(c)]}
    end
  end

  def self.offsets()
    (0..3).map {|n| n * 256}
  end

  def self.cardImageSize()
    [164, 252]
  end

  def self.cardSpriteSize()
    cardImageSize.then do |cw, ch|
      [@cardSpriteWidth, @cardSpriteWidth * (ch.to_f / cw.to_f)]
    end
  end

end# Skin
