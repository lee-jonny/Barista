cask "barista" do
  version "0.2.3"
  sha256 "a83f5d6420e6715e5ffc52e13359c247a568dc5a835a6907b6b8401cd52ecb15"

  url "https://github.com/willofi/Barista/releases/download/v#{version}/Barista-#{version}-macos27-arm64.zip"
  name "Barista"
  desc "Hide and reveal menu bar items"
  homepage "https://github.com/willofi/Barista"

  depends_on arch: :arm64
  depends_on macos: :golden_gate

  app "Barista.app"
end
