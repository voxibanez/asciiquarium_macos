class AsciiFishtank < Formula
  desc "ASCII aquarium screen saver for macOS"
  homepage "https://github.com/voxibanez/asciiquarium_macos"
  url "https://github.com/voxibanez/asciiquarium_macos.git", branch: "main"
  version "1.0"

  depends_on macos: :sonoma

  def install
    system "make", "clean"
    system "make"
    prefix.install "AsciiFishtank.saver"
  end

  def caveats
    <<~EOS
      To enable the screen saver:
        mkdir -p "$HOME/Library/Screen Savers"
        ln -sfn "#{opt_prefix}/AsciiFishtank.saver" "$HOME/Library/Screen Savers/AsciiFishtank.saver"

      Then open System Settings > Screen Saver and select ASCII Fishtank.
    EOS
  end

  test do
    assert_path_exists prefix/"AsciiFishtank.saver/Contents/MacOS/AsciiFishtank"
    system "codesign", "--verify", prefix/"AsciiFishtank.saver"
  end
end
