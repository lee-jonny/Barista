cask "barista" do
  version "0.2.4"
  sha256 "e4b234afa39086330a5d9b702fa33e63388fc3060262950ed21afc4ddbb99b77"

  url "https://github.com/willofi/Barista/releases/download/v#{version}/Barista-#{version}-macos27-arm64.zip"
  name "Barista"
  desc "Hide and reveal menu bar items"
  homepage "https://github.com/willofi/Barista"

  depends_on arch: :arm64
  depends_on macos: :golden_gate

  app "Barista.app"
end
