#!/bin/zsh
# Builds a release copy, puts it in ~/Applications and starts it.
set -euo pipefail
cd "$(dirname "$0")/.."

app=$(./scripts/build.sh Release | tail -1)
pkill -x Breather || true
mkdir -p ~/Applications
rm -rf ~/Applications/Breather.app
cp -R "$app" ~/Applications/
open ~/Applications/Breather.app
echo "Installed ~/Applications/Breather.app"
