cask "barista" do
  version "0.2.5"
  sha256 "7f9e9cc3e40f818010d28158e180edea56359d4959628201d91e5df47921b9bd"

  url "https://github.com/willofi/Barista/releases/download/v#{version}/Barista-#{version}-macos27-arm64.zip"
  name "Barista"
  desc "Hide and reveal menu bar items"
  homepage "https://github.com/willofi/Barista"

  depends_on arch: :arm64
  depends_on macos: :golden_gate

  app "Barista.app"
end
