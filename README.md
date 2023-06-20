# Solitaire game made with RubySketch

## How to use

### Run local scripts on macOS

```sh
 $ gem install rubysketch
 $ ruby -Ilib -rrubysketch/solitaire -e ''
```

### Run on macOS using RubyGems

```sh
 $ gem install rubysketch-solitaire
 $ ruby -rrubysketch/solitaire -e ''
```

## How to release to AppStore

### Upload to TestFlight on local macOS

1. Edit ChangeLog.md and commit
2. Make sure you have a config.yml file
3. run "rake release:testflight"

## License

see [LICENSE](LICENSE) file
