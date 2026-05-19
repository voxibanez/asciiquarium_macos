# ASCII Fishtank

ASCII Fishtank is a macOS screen saver that brings the classic terminal
aquarium animation into System Settings. It is built in Swift with
ScreenSaver.framework and packaged as `AsciiFishtank.saver`.

This project is a Swift/macOS port inspired by and derived from
[Asciiquarium](https://robobunny.com/projects/asciiquarium/) v1.1 by
Kirk Baucom.

## Install with Homebrew

The recommended install path is the Homebrew cask. It installs the notarized
release build directly into your user screen savers folder.

```sh
brew tap voxibanez/asciiquarium_macos https://github.com/voxibanez/asciiquarium_macos.git
brew install --cask ascii-fishtank
```

Then open System Settings > Screen Saver and select ASCII Fishtank.

To upgrade later:

```sh
brew update
brew upgrade --cask ascii-fishtank
```

To uninstall:

```sh
brew uninstall --cask ascii-fishtank
brew untap voxibanez/asciiquarium_macos
```

### Build from source with Homebrew

If you prefer Homebrew to compile from the current tap source, install the
formula instead of the cask:

```sh
brew install ascii-fishtank
```

The formula installs the saver under Homebrew's prefix. Link it into your user
screen savers folder so macOS can find it:

```sh
mkdir -p "$HOME/Library/Screen Savers"
ln -sfn "$(brew --prefix ascii-fishtank)/AsciiFishtank.saver" "$HOME/Library/Screen Savers/AsciiFishtank.saver"
```

Then open System Settings > Screen Saver and select ASCII Fishtank.

To reinstall the formula from source during development:

```sh
brew update
brew reinstall --build-from-source ascii-fishtank
```

To remove the formula install:

```sh
rm -f "$HOME/Library/Screen Savers/AsciiFishtank.saver"
brew uninstall ascii-fishtank
brew untap voxibanez/asciiquarium_macos
```

## Build from source

### Requirements

- macOS 14 Sonoma or newer
- Xcode Command Line Tools

To install the Xcode Command Line Tools:

```sh
xcode-select --install
```

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

Run the test suite:

```sh
make test
```

Create a distributable zip locally:

```sh
make package VERSION=local
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
make test
brew style Formula/ascii-fishtank.rb
brew audit --strict --formula voxibanez/asciiquarium_macos/ascii-fishtank
brew test ascii-fishtank
```

To reinstall from the tap source during development:

```sh
brew update
brew reinstall --build-from-source ascii-fishtank
```

## Homebrew cask maintenance

The cask is stored in:

```text
Casks/ascii-fishtank.rb
```

It installs the notarized zip from the matching GitHub Release. Update the
cask `version` when publishing a new release tag, then replace the checksum if
using a pinned SHA:

```sh
shasum -a 256 AsciiFishtank-v1.0.8.zip
brew style Casks/ascii-fishtank.rb
```

## GitHub releases

The GitHub Actions workflow runs on pull requests, pushes to `main`, and tags
matching `v*`.

For every run, it:

- runs `make test`
- builds `AsciiFishtank.saver`
- packages a zip artifact from the built saver, `LICENSE`, `NOTICE`, and `README.md`
- uploads the zip as a workflow artifact

For tag pushes, it also creates or updates a GitHub Release and uploads the
same zip as a release asset. Tagged releases are Developer ID signed,
submitted to Apple for notarization, stapled, verified, and then packaged.

### GitHub secrets for notarized releases

Tagged release builds require these repository secrets:

```text
APPLE_CERTIFICATE_BASE64
APPLE_CERTIFICATE_PASSWORD
APPLE_ID
APPLE_TEAM_ID
APPLE_APP_PASSWORD
KEYCHAIN_PASSWORD
```

To set them, open GitHub > repository Settings > Secrets and variables >
Actions > New repository secret.

`APPLE_CERTIFICATE_BASE64` is a base64-encoded `.p12` export of your
Developer ID Application certificate:

```sh
base64 -i DeveloperIDApplication.p12 | pbcopy
```

`APPLE_CERTIFICATE_PASSWORD` is the password used when exporting that `.p12`.

`APPLE_ID` is your Apple ID email. `APPLE_TEAM_ID` is the 10-character Apple
Developer Team ID. `APPLE_APP_PASSWORD` is an app-specific password generated
at <https://appleid.apple.com/account/manage>. `KEYCHAIN_PASSWORD` can be any
strong random value used only for the temporary CI keychain.

To publish a release:

```sh
git tag vx.y.z
git push origin vx.y.z
```

## License and attribution

ASCII Fishtank is licensed under GPL-2.0-or-later. See [LICENSE](LICENSE) for
the full license text and [NOTICE](NOTICE) for attribution and art provenance.

This port is based on Asciiquarium v1.1, Copyright (C) 2013 Kirk Baucom,
which is licensed under GPL-2.0-or-later. The original Asciiquarium README
credits Joan Stark for most of the ASCII art.
