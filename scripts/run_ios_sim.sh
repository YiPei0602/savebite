#!/usr/bin/env bash
# Run the Flutter app on the *first* iOS simulator Flutter lists (by UDID).
#
# Why: Multiple simulators can share names (e.g. "iPhone 17" per OS runtime). Picking the wrong UDID or
# having no runtime matching Xcode's Simulator SDK yields:
#   "Unable to find a destination matching ..."
#
# Prerequisites: Xcode's **Simulator runtime** major.minor must match the **iphonesimulator SDK**
# version (run `scripts/assert_ios_simulator_runtime.sh` separately for details).
#
# Usage (from repo root):
#   ./scripts/run_ios_sim.sh
#   ./scripts/run_ios_sim.sh --dart-define=FOO=bar

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "${SCRIPT_DIR}/assert_ios_simulator_runtime.sh"

DEVICE="$(python3 - <<'PY'
import json, subprocess, sys
try:
    out = subprocess.check_output(
        ["flutter", "devices", "--machine"],
        text=True,
        stderr=subprocess.STDOUT,
    )
except subprocess.CalledProcessError as e:
    print(e.output or str(e), file=sys.stderr)
    sys.exit(1)
devices = json.loads(out)
for d in devices:
    if d.get("targetPlatform") == "ios" and d.get("emulator"):
        print(d["id"])
        sys.exit(0)
print("No iOS simulator in `flutter devices`. Open Simulator or create a device.", file=sys.stderr)
sys.exit(1)
PY
)"

echo "Using iOS simulator UDID: $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator 2>/dev/null || true
exec flutter run -d "$DEVICE" "$@"
