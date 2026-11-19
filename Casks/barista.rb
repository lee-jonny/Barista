cask "barista" do
  version "0.2.2"
  sha256 "cbe3dd0b2a6bf8b1dde91fa5bf475d2a6a76bd571178444d362abcf711ec6656"

  url "https://github.com/willofi/Barista/releases/download/v#{version}/Barista-#{version}-macos27-arm64.zip"
  name "Barista"
  desc "Hide and reveal menu bar items"
  homepage "https://github.com/willofi/Barista"

  depends_on arch: :arm64
  depends_on macos: ">= :golden_gate"

  app "Barista.app"
end
