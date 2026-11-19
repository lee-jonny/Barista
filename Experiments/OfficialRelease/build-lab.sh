#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h:h}"
LAB_DIR="${PWD}/.build/official-release"
LAB_APP="${LAB_DIR}/BaristaLab.app"
mkdir -p "${LAB_APP}/Contents/MacOS" "${LAB_DIR}/module-cache"
xcrun swiftc -swift-version 6 -target arm64-apple-macos27.0 \
  -module-cache-path "${LAB_DIR}/module-cache" \
  Experiments/OfficialRelease/OverflowPlan.swift Experiments/OfficialRelease/OverflowPlanChecks.swift \
  -o "${LAB_DIR}/overflow-plan-checks"
"${LAB_DIR}/overflow-plan-checks"
xcrun swiftc -swift-version 6 -target arm64-apple-macos27.0 \
  -module-cache-path "${LAB_DIR}/module-cache" -typecheck \
  Experiments/OfficialRelease/PublicCaptureProbe.swift
# Swift's top-level entry point is named main.swift in a multiple-file executable.
cp Experiments/OfficialRelease/SandboxGeometryLab.swift "${LAB_DIR}/main.swift"
xcrun swiftc -swift-version 6 -target arm64-apple-macos27.0 \
  -module-cache-path "${LAB_DIR}/module-cache" \
  Experiments/OfficialRelease/OverflowPlan.swift "${LAB_DIR}/main.swift" \
  -o "${LAB_APP}/Contents/MacOS/BaristaLab"
cat > "${LAB_APP}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.eden.barista.research.geometry</string>
<key>CFBundleName</key><string>BaristaLab</string>
<key>CFBundleExecutable</key><string>BaristaLab</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>27.0</string>
</dict></plist>
PLIST
codesign --force --sign - --options runtime \
  --entitlements Experiments/OfficialRelease/Lab.entitlements "${LAB_APP}"
codesign --verify --strict "${LAB_APP}"
print "Built sandbox experiment: ${LAB_APP}"
