class Settings

  def initialize(path)
    @path = path or raise 'invalid path'
    @hash = load path
  end

  def clear()
    hash.clear
    save @path
  end

  def []=(key, value)
    if value != hash[key]
      hash[key] = value
      save @path
    end
    value
  end

  def [](key)
    hash[key]
  end

  def to_json()
    hash.to_json
  end

  private

  def hash()
    @hash ||= {}
  end

  def save(path)
    File.write path, to_json
  end

  def load(path)
    @hash = File.exist?(path) ? JSON.parse(File.read path) : {}
  end

end# Settings
