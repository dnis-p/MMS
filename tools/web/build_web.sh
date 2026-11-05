#!/usr/bin/env bash
# Builds the browser version into build/web/ (the standard Godot export, which CI publishes on GitHub
# Pages) and zips it as build/dig-web.zip for itch.io or any static host.
#
# Needs Godot 4.7 on PATH as `godot` with the Web export templates installed.
set -euo pipefail
cd "$(dirname "$0")/../.."

rm -rf build/web
mkdir -p build/web
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-release "Web" build/web/index.html
(cd build/web && zip -q -r ../dig-web.zip .)
echo "Built build/web (zip: build/dig-web.zip)"
