# ASCII Fishtank

ASCII Fishtank is a macOS screen saver built with Swift and ScreenSaver.framework.

## Install with Homebrew

```sh
brew tap voxibanez/asciiquarium_macos
brew install ascii-fishtank
mkdir -p "$HOME/Library/Screen Savers"
ln -sfn "$(brew --prefix ascii-fishtank)/AsciiFishtank.saver" "$HOME/Library/Screen Savers/AsciiFishtank.saver"
```

Then open System Settings > Screen Saver and select ASCII Fishtank.

## Build from source

```sh
make
make install
```
