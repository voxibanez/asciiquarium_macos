cask "ascii-fishtank" do
  version "1.0.9"
  sha256 :no_check

  url "https://github.com/voxibanez/asciiquarium_macos/releases/download/v#{version}/AsciiFishtank-v#{version}.zip",
      verified: "github.com/voxibanez/asciiquarium_macos/"
  name "ASCII Fishtank"
  desc "ASCII aquarium screen saver"
  homepage "https://github.com/voxibanez/asciiquarium_macos"

  depends_on macos: :sonoma

  screen_saver "AsciiFishtank-v#{version}/AsciiFishtank.saver"

  caveats do
    <<~EOS
      Open System Settings > Screen Saver and select ASCII Fishtank.
    EOS
  end
end
