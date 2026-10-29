#!/usr/bin/env bash
# Builds a signed arm64 APK into build/mms-prototype.apk.
#
# Needs: Godot 4.7 on PATH as `godot` with Android export templates installed,
# Java 17+, and python3 with the `cryptography` package.
#
# Godot only *checks* that an Android SDK exists before exporting; we export
# unsigned and sign with tools/android/sign_apk_v2.py, so a stand-in SDK
# folder is enough. Set ANDROID_SDK_PATH to use a real SDK instead.
set -euo pipefail
cd "$(dirname "$0")/../.."

SDK="${ANDROID_SDK_PATH:-$PWD/build/stand-in-sdk}"
if [ -z "${ANDROID_SDK_PATH:-}" ]; then
	mkdir -p "$SDK/platform-tools" "$SDK/build-tools/36.0.0"
	printf '#!/bin/sh\nexit 0\n' > "$SDK/platform-tools/adb"
	printf '#!/bin/sh\necho 0\n' > "$SDK/build-tools/36.0.0/apksigner"
	chmod +x "$SDK/platform-tools/adb" "$SDK/build-tools/36.0.0/apksigner"
fi
JAVA_HOME="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"

# Point Godot's editor settings at Java and the SDK.
SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
mkdir -p "$SETTINGS_DIR"
SETTINGS=$(ls "$SETTINGS_DIR"/editor_settings-4.*.tres 2>/dev/null | head -1 || true)
if [ -z "$SETTINGS" ]; then
	SETTINGS="$SETTINGS_DIR/editor_settings-4.7.tres"
	printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' > "$SETTINGS"
fi
python3 - "$SETTINGS" "$SDK" "$JAVA_HOME" <<'PY'
import re, sys
path, sdk, java = sys.argv[1:]
s = open(path).read()
s = re.sub(r'\nexport/android/(android_sdk_path|java_sdk_path) = "[^"]*"', '', s)
s = s.replace('[resource]\n', '[resource]\nexport/android/android_sdk_path = "%s"\nexport/android/java_sdk_path = "%s"\n' % (sdk, java), 1)
open(path, 'w').write(s)
PY

mkdir -p build
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-release "Android" build/mms-unsigned.apk
python3 tools/android/sign_apk_v2.py \
	--key tools/android/debug-key/debug_key.pem \
	--cert tools/android/debug-key/debug_cert.der \
	build/mms-unsigned.apk build/mms-prototype.apk
rm build/mms-unsigned.apk
echo "Built build/mms-prototype.apk"
