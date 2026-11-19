#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
archive="Barista-${version}-macos27-arm64.zip"
release_url="https://github.com/willofi/Barista/releases/download/v${version}"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# Verify the public downloads a new Homebrew user will actually receive.
curl --fail --silent --show-error --location "$release_url/$archive" --output "$work_dir/$archive"
curl --fail --silent --show-error --location "$release_url/SHA256SUMS" --output "$work_dir/SHA256SUMS"
(cd "$work_dir" && shasum -a 256 "$archive" > actual.sha256 && cmp actual.sha256 SHA256SUMS)
published_version=$(unzip -p "$work_dir/$archive" Barista.app/Contents/Info.plist | plutil -extract CFBundleShortVersionString raw -)
[[ "$published_version" == "$version" ]] || { print -u2 "Unexpected published app version"; exit 1; }
read -r digest archive_name < "$work_dir/actual.sha256"

/usr/bin/ruby - "$version" "$digest" <<'RUBY'
require "rubygems/version"
require "tempfile"

version, digest = ARGV
path = "Casks/barista.rb"
cask = File.read(path)
version_line = /^  version "([0-9]+(?:\.[0-9]+)*)"$/
digest_line = /^  sha256 "([0-9a-f]{64})"$/
old_version = cask[version_line, 1] or abort "Missing cask version"
old_digest = cask[digest_line, 1] or abort "Missing cask checksum"
abort "Refusing to downgrade the cask" if Gem::Version.new(version) < Gem::Version.new(old_version)
if Gem::Version.new(version) == Gem::Version.new(old_version)
  abort "Published checksum changed for v#{old_version}" unless digest == old_digest
  puts "Cask already matches the published ZIP"
  exit
end

updated = cask.sub(version_line, %(  version "#{version}")).sub(digest_line, %(  sha256 "#{digest}"))
Tempfile.create("barista-cask", File.dirname(path)) do |file|
  file.write(updated)
  file.close
  File.chmod(File.stat(path).mode & 0777, file.path)
  File.rename(file.path, path)
end
puts "Updated #{path} to v#{version}"
RUBY
