#!/usr/bin/env bash
# Builds the browser version.
#
#   build/web/        standard Godot export: upload as a zip to itch.io (or any static host)
#   build/web-packed/ same game with the engine gzipped and started by tools/web/launcher.html,
#                     for hosts that cap file size (every file stays under ~10 MB)
#
# Needs Godot 4.7 on PATH as `godot` with the Web export templates installed.
set -euo pipefail
cd "$(dirname "$0")/../.."

rm -rf build/web build/web-packed
mkdir -p build/web build/web-packed
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-release "Web" build/web/index.html
(cd build/web && zip -q -r ../mms-web.zip .)

cp build/web/index.js build/web/index.audio.worklet.js build/web/index.audio.position.worklet.js build/web-packed/
gzip -9 -c build/web/index.wasm > build/web-packed/engine.gz.wasm
gzip -9 -c build/web/index.pck > build/web-packed/game.gz.wasm
python3 - <<'PY'
import json, os, re
packed = 'build/web-packed'
page = open('tools/web/launcher.html').read()
sizes = {
    'engine.gz.wasm': os.path.getsize(f'{packed}/engine.gz.wasm'),
    'game.gz.wasm': os.path.getsize(f'{packed}/game.gz.wasm'),
}
for name, size in sizes.items():
    page = re.sub(r"(file: '%s', type: '[^']+', size: )\d+" % re.escape(name), r"\g<1>%d" % size, page)
html = open('build/web/index.html').read()
config = json.loads(re.search(r'const GODOT_CONFIG = (\{.*?\});', html).group(1))
config['ensureCrossOriginIsolationHeaders'] = False
page = re.sub(r'const GODOT_CONFIG = \{.*?\};', 'const GODOT_CONFIG = %s;' % json.dumps(config, separators=(',', ':')), page)
total = sum(sizes.values()) / 1048576
page = re.sub(r'0\.0 / [\d.]+ MB', '0.0 / %.1f MB' % total, page)
open(f'{packed}/game.html', 'w').write(page)
PY
echo "Built build/web (zip: build/mms-web.zip) and build/web-packed"
