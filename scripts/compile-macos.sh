#!/usr/bin/env bash
# Compile-only workflow for macOS. Does NOT flash the board.
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v python3.12 >/dev/null 2>&1; then
  PYTHON="$(command -v python3.12)"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON="$(command -v python3)"
else
  echo "Python >= 3.12 required. On macOS: brew install python@3.12" >&2
  exit 1
fi

"$PYTHON" - <<'PY'
import sys
if sys.version_info < (3, 12):
    raise SystemExit("ESPHome 2026.10.2 requires Python >=3.12. Run: brew install python@3.12")
print("Using Python", sys.version.split()[0])
PY

if [ ! -e secrets.yaml ]; then
  "$PYTHON" - <<'PY'
import base64
import os
from pathlib import Path
key = base64.b64encode(os.urandom(32)).decode("ascii")
file = Path("secrets.yaml")
# Exclusive create prevents inadvertently replacing an existing device key.
with file.open("x", encoding="utf-8") as f:
    f.write("# Private device key. Back this file up securely. Do not commit.\n")
    f.write(f'api_encryption_key: "{key}"\n')
os.chmod(file, 0o600)
print("Created private secrets.yaml with a unique API key (value hidden).")
PY
else
  "$PYTHON" - <<'PY'
import base64
from pathlib import Path
import re
text = Path("secrets.yaml").read_text(encoding="utf-8")
match = re.search(r'^api_encryption_key:\s*["\']?([^"\'\s#]+)', text, re.M)
if not match:
    raise SystemExit("secrets.yaml exists but has no api_encryption_key; keep your old key and correct the file.")
try:
    raw = base64.b64decode(match.group(1), validate=True)
except ValueError as exc:
    raise SystemExit("Invalid Base64 API key in secrets.yaml") from exc
if len(raw) != 32:
    raise SystemExit("API key in secrets.yaml must decode to exactly 32 bytes.")
print("Using existing private device key; not generating or overwriting it.")
PY
fi

if [ ! -d .venv ]; then
  "$PYTHON" -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install "esphome==2026.10.2"
echo "========== ESPHome version =========="
esphome version
echo "========== ESPHome configuration validation =========="
esphome config esp32-rlcd42.yaml >/dev/null
echo "PASS: ESPHome config"
echo "========== Compile firmware (no flash) =========="
esphome compile esp32-rlcd42.yaml
echo "PASS: ESPHome compile. No firmware has been flashed."
