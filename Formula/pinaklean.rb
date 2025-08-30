class Pinaklean < Formula
  desc "Safe macOS cleanup toolkit for developers - Where Intelligence Meets Cleanliness"
  homepage "https://github.com/Pinak-Setu/Pinaklean"
  url "https://github.com/Pinak-Setu/Pinaklean/releases/download/v1.0.0/pinaklean-cli-v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_FROM_RELEASES"
  license "Apache-2.0"
  version "1.0.0"

  depends_on "swift" => :build
  depends_on :macos

  def install
    # Build the CLI tool
    system "swift", "build",
           "--configuration", "release",
           "--product", "pinaklean-cli",
           "--disable-sandbox"

    # Install the binary
    bin.install ".build/release/pinaklean-cli" => "pinaklean"

    # Create man page (optional)
    # man1.install "man/pinaklean.1"
  end

  test do
    # Basic functionality test
    system "#{bin}/pinaklean", "--help"

    # Version test
    assert_match "2.0.0", shell_output("#{bin}/pinaklean --version")

    # Dry run test (should not fail)
    system "#{bin}/pinaklean", "scan", "--dry-run", "--categories", "temp"
  end

  def caveats
    <<~EOS
      Pinaklean has been installed as a CLI tool. For the GUI version:

      1. Download the GUI app from GitHub Releases
      2. Move Pinaklean.app to your Applications folder
      3. Or build it yourself:
         git clone https://github.com/Pinak-Setu/Pinaklean.git
         cd Pinaklean/PinakleanApp
         swift run Pinaklean

      For more information, visit: https://github.com/Pinak-Setu/Pinaklean
    EOS
  end
end
