class Settings

  def initialize(path)
    @path = path or raise 'invalid path'
    @hash = load path
  end

  def []=(key, value)
    hash[key] = value
    save @path
  end

  def [](key)
    hash[key]
  end

  private

  def hash()
    @hash ||= {}
  end

  def save(path)
    File.write path, hash.to_json
  end

  def load(path)
    @hash = File.exist?(path) ? JSON.parse(File.read path) : {}
  end

end# Settings
