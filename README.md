# ASCII Fishtank

ASCII Fishtank is a macOS screen saver built with Swift and ScreenSaver.framework.

This project is a Swift/macOS port inspired by and derived from
[Asciiquarium](https://robobunny.com/projects/asciiquarium/) v1.1 by Kirk Baucom.

## Install with Homebrew

```sh
brew tap voxibanez/asciiquarium_macos https://github.com/voxibanez/asciiquarium_macos.git
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

## License and attribution

AsciiFishtank is licensed under GPL-2.0-or-later. See [LICENSE](LICENSE) for
the full license text and [NOTICE](NOTICE) for attribution details.

This port is based on Asciiquarium v1.1, Copyright (C) 2013 Kirk Baucom,
which is licensed under GPL-2.0-or-later. The original Asciiquarium README
credits Joan Stark for most of the ASCII art.
