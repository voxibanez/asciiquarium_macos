cask "ascii-fishtank" do
  version "1.1.0"
  sha256 "51e3671561f17255f2dd9e9abe30cd2fb8e8951838090a8694dd48fba612a3f0"

  url "https://github.com/voxibanez/asciiquarium_macos/releases/download/v#{version}/AsciiFishtank-v#{version}.zip",
      verified: "github.com/voxibanez/asciiquarium_macos/"
  name "ASCII Fishtank"
  desc "ASCII aquarium screen saver"
  homepage "https://github.com/voxibanez/asciiquarium_macos"

  depends_on macos: :sonoma

  screen_saver "AsciiFishtank-v#{version}/AsciiFishtank.saver"

  postflight do
    system_command "/usr/bin/killall",
                   args:         ["legacyScreenSaver"],
                   sudo:         false,
                   must_succeed: false
    system_command "/usr/bin/killall",
                   args:         ["ScreenSaverEngine"],
                   sudo:         false,
                   must_succeed: false
  end

  uninstall_postflight do
    system_command "/usr/bin/killall",
                   args:         ["legacyScreenSaver"],
                   sudo:         false,
                   must_succeed: false
    system_command "/usr/bin/killall",
                   args:         ["ScreenSaverEngine"],
                   sudo:         false,
                   must_succeed: false
  end

  caveats do
    <<~EOS
      Open System Settings > Screen Saver and select ASCII Fishtank.

      If macOS still shows an older copy, quit and reopen System Settings.
    EOS
  end
end
