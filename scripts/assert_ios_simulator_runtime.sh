#!/usr/bin/env bash
# Exit 0 only if CoreSimulator has a runtime whose *build number* matches the
# active iphonesimulator SDK (e.g. 23F73). Marketing version alone is not enough —
# Xcode 26.5's SDK can be 26.5 while runtimes stop at 26.4, which causes:
#
# - Flutter/xcodebuild: no Simulator destinations
# - actool (often in Stripe Pods): "No simulator runtime version from [...] available
#   to use with iphonesimulator SDK version 23F73"
#
# Fix: Xcode → Settings → Platforms → install the iOS Simulator for this Xcode, or:
#      xcodebuild -downloadPlatform iOS

set -euo pipefail

python3 - <<'PY'
import json, plistlib, subprocess, sys
from pathlib import Path

def fail(msg_lines):
    for line in msg_lines:
        print(line, file=sys.stderr)
    sys.exit(2)

try:
    sdk_path = subprocess.check_output(
        ["xcrun", "--show-sdk-path", "--sdk", "iphonesimulator"],
        text=True,
    ).strip()
except subprocess.CalledProcessError:
    fail(
        [
            "error: xcrun --show-sdk-path --sdk iphonesimulator failed.",
            "  Install Xcode and select it: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer",
        ]
    )

ver_plist = Path(sdk_path) / "System" / "Library" / "CoreServices" / "SystemVersion.plist"
if not ver_plist.is_file():
    fail([f"error: missing SDK SystemVersion.plist at {ver_plist}"])

with ver_plist.open("rb") as f:
    ver = plistlib.load(f)

sdk_product = str(ver.get("ProductVersion", "")).strip()
sdk_build = str(ver.get("ProductBuildVersion", "")).strip()
if not sdk_build:
    fail(["error: ProductBuildVersion missing from simulator SDK plist."])

try:
    raw = subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "-j"], text=True)
    data = json.loads(raw)
except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
    fail([f"error: could not list simulator runtimes: {e}"])

runtime_builds = []
for r in data.get("runtimes") or []:
    if not r.get("isAvailable"):
        continue
    b = str(r.get("buildversion") or "").strip()
    if b:
        runtime_builds.append((r.get("name", "?"), b))

if any(b == sdk_build for _, b in runtime_builds):
    sys.exit(0)

print("", file=sys.stderr)
print(
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    file=sys.stderr,
)
print(
    " iOS Simulator runtime does not match Xcode’s Simulator SDK (build mismatch)",
    file=sys.stderr,
)
print(
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    file=sys.stderr,
)
print("", file=sys.stderr)
print(f"  Simulator SDK:  iOS {sdk_product}  (ProductBuildVersion {sdk_build})", file=sys.stderr)
print("  Installed simulator runtimes (name → build):", file=sys.stderr)
for name, b in runtime_builds:
    print(f"    {name:16} → {b}", file=sys.stderr)
print("", file=sys.stderr)
print(
    f"None of the installed runtimes use build **{sdk_build}**, which this Xcode SDK requires.",
    file=sys.stderr,
)
print(
    'That breaks asset catalogs (see Stripe Pods / actool: "SDK version '
    + sdk_build
    + '").',
    file=sys.stderr,
)
print("", file=sys.stderr)
print("Fix (recommended):", file=sys.stderr)
print("  Xcode → Settings → Platforms → \"+\" → install **iOS Simulator** for this Xcode", file=sys.stderr)
print("", file=sys.stderr)
print(
    "Fix (CLI — large download; Apple ID signed in under Xcode → Settings → Accounts):",
    file=sys.stderr,
)
print("  xcodebuild -downloadPlatform iOS", file=sys.stderr)
print("", file=sys.stderr)
sys.exit(2)
PY
