#!/bin/zsh
# Builds Breather into build/. Pass "Release" for a release build.
set -euo pipefail
cd "$(dirname "$0")/.."

config="${1:-Debug}"
xcodegen generate --quiet
xcodebuild -project Breather.xcodeproj -scheme Breather -configuration "$config" \
  -derivedDataPath build/DerivedData -quiet build
echo "build/DerivedData/Build/Products/$config/Breather.app"
