# ASCII Fishtank

ASCII Fishtank is a macOS screen saver that brings the classic terminal
aquarium animation into System Settings. It is built in Swift with
ScreenSaver.framework and packaged as `AsciiFishtank.saver`.

This project is a Swift/macOS port inspired by and derived from
[Asciiquarium](https://robobunny.com/projects/asciiquarium/) v1.1 by
Kirk Baucom.

## Requirements

- macOS 14 Sonoma or newer
- Xcode Command Line Tools
- Homebrew, if installing with `brew`

To install the Xcode Command Line Tools:

```sh
xcode-select --install
```

## Install with Homebrew

Because this repository is also the tap, use the explicit tap URL:

```sh
brew tap voxibanez/asciiquarium_macos https://github.com/voxibanez/asciiquarium_macos.git
brew install ascii-fishtank
```

Homebrew installs the saver under its prefix. Link it into your user screen
savers folder so macOS can find it:

```sh
mkdir -p "$HOME/Library/Screen Savers"
ln -sfn "$(brew --prefix ascii-fishtank)/AsciiFishtank.saver" "$HOME/Library/Screen Savers/AsciiFishtank.saver"
```

Then open System Settings > Screen Saver and select ASCII Fishtank.

To upgrade later:

```sh
brew update
brew upgrade ascii-fishtank
```

To uninstall:

```sh
rm -f "$HOME/Library/Screen Savers/AsciiFishtank.saver"
brew uninstall ascii-fishtank
brew untap voxibanez/asciiquarium_macos
```

## Build from source

Clone the repository and build the saver bundle:

```sh
git clone https://github.com/voxibanez/asciiquarium_macos.git
cd asciiquarium_macos
make
```

The build creates:

```text
AsciiFishtank.saver
```

Install it for the current user:

```sh
make install
```

Then open System Settings > Screen Saver and select ASCII Fishtank.

To remove the manually installed saver:

```sh
make uninstall
```

To remove build output:

```sh
make clean
```

## Build details

The Makefile compiles the Swift sources directly with `swiftc`, links against
`ScreenSaver`, `AppKit`, and `QuartzCore`, copies the bundled ASCII art and
metadata into the saver bundle, and ad-hoc signs the result with `codesign`.

The main source files live in:

```text
Sources/AsciiFishtank
```

The ASCII art resources live in:

```text
Sources/AsciiFishtank/Resources/Art
```

## Homebrew formula maintenance

The formula is stored in:

```text
Formula/ascii-fishtank.rb
```

Useful local checks:

```sh
brew style Formula/ascii-fishtank.rb
brew audit --strict --formula voxibanez/asciiquarium_macos/ascii-fishtank
brew test ascii-fishtank
```

To reinstall from the tap source during development:

```sh
brew update
brew reinstall --build-from-source ascii-fishtank
```

## License and attribution

ASCII Fishtank is licensed under GPL-2.0-or-later. See [LICENSE](LICENSE) for
the full license text and [NOTICE](NOTICE) for attribution and art provenance.

This port is based on Asciiquarium v1.1, Copyright (C) 2013 Kirk Baucom,
which is licensed under GPL-2.0-or-later. The original Asciiquarium README
credits Joan Stark for most of the ASCII art.
