cask "ascii-fishtank" do
  version "1.1.1"
  sha256 "5684f6f57edceaed62794f46d2b42bbe55ecce36dd68238f5c26b23e15da6c99"

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
                   must_succeed: false,
                   print_stderr: false
    system_command "/usr/bin/killall",
                   args:         ["ScreenSaverEngine"],
                   sudo:         false,
                   must_succeed: false,
                   print_stderr: false
  end

  uninstall_postflight do
    system_command "/usr/bin/killall",
                   args:         ["legacyScreenSaver"],
                   sudo:         false,
                   must_succeed: false,
                   print_stderr: false
    system_command "/usr/bin/killall",
                   args:         ["ScreenSaverEngine"],
                   sudo:         false,
                   must_succeed: false,
                   print_stderr: false
  end

  caveats do
    <<~EOS
      Open System Settings > Screen Saver and select ASCII Fishtank.

      If macOS still shows an older copy, quit and reopen System Settings.
    EOS
  end
end
