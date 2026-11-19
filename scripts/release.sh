#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
APP="${PWD}/build/Barista.app"
[[ -d "$APP" ]] || { print -u2 'Run scripts/build.sh first'; exit 1; }
/usr/bin/codesign --verify --deep --strict "$APP"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
MINIMUM=$(/usr/libexec/PlistBuddy -c 'Print LSMinimumSystemVersion' "$APP/Contents/Info.plist")
[[ "$MINIMUM" == '27.0' ]] || { print -u2 'Unexpected minimum macOS'; exit 1; }
[[ "$(/usr/bin/lipo -archs "$APP/Contents/MacOS/Barista")" == 'arm64' ]] || { print -u2 'Unexpected architecture'; exit 1; }
for key in CFBundleShortVersionString CFBundleVersion; do
  built=$(/usr/libexec/PlistBuddy -c "Print $key" "$APP/Contents/Info.plist")
  source_value=$(/usr/libexec/PlistBuddy -c "Print $key" Resources/Info.plist)
  [[ "$built" == "$source_value" ]] || { print -u2 "Rebuild the app: $key differs"; exit 1; }
done
mkdir -p dist Casks
ARCHIVE="Barista-${VERSION}-macos27-arm64.zip"
# ditto replaces the archive; never update an old ZIP in place.
rm -f "dist/$ARCHIVE"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/$ARCHIVE"
(cd dist && /usr/bin/shasum -a 256 "$ARCHIVE" > SHA256SUMS)
print "Release: ${PWD}/dist/$ARCHIVE"
read -r digest archive_name < dist/SHA256SUMS
[[ "$archive_name" == "$ARCHIVE" && ${#digest} == 64 ]]
cat > Casks/barista.rb <<CASK
cask "barista" do
  version "${VERSION}"
  sha256 "${digest}"

  url "https://github.com/willofi/Barista/releases/download/v#{version}/Barista-#{version}-macos27-arm64.zip"
  name "Barista"
  desc "Hide and reveal menu bar items"
  homepage "https://github.com/willofi/Barista"

  depends_on arch: :arm64
  depends_on macos: ">= :golden_gate"

  app "Barista.app"
end
CASK
print "Updated Casks/barista.rb for v${VERSION}"
