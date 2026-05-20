cask "ascii-fishtank" do
  version "1.0.9"
  sha256 "80f0d2e2acb56e292b7762686d114e68bb95b5df6f07c92c047ad3500b71cfd9"

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
