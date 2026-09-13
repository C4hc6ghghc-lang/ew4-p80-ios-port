#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
LEAN="$ROOT/SOURCE_LEAN/EW4_Web_Port_v0.61"
NATIVE="$ROOT/SOURCE_NATIVE/EW4_iOS_NativePort"

printf '\n== Unified current source-truth freeze ==\n'
python3 "$ROOT/VERIFY_SOURCE_LEAN_FROZEN.py"

printf '\n== Mature truth regression (exact frozen 126-file list) ==\n'
command -v node >/dev/null || { echo 'ERROR: node required for the preserved mature-source regression gate' >&2; exit 2; }
log="$ROOT/P80_CODEX_JS_REGRESSION.log"
: > "$log"
pass=0; fail=0
cd "$LEAN"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if node "$f" >> "$log" 2>&1; then pass=$((pass+1)); else echo "FAILED $f" | tee -a "$log"; tail -n 70 "$log"; fail=$((fail+1)); fi
done < "$ROOT/js_test_list_126.txt"
echo "JS_TEST_FILES_PASS=$pass FAIL=$fail TOTAL=$((pass+fail))" | tee -a "$log"
[ "$pass" -eq 126 ] && [ "$fail" -eq 0 ] || { echo 'ERROR: mature SOURCE_LEAN regression failed' >&2; exit 2; }

printf '\n== P80 map/unit/dynamic-state evidence gate ==\n'
python3 "$ROOT/P80_MAP_UNIT_DYNAMIC_STATE_AUDIT.py" | tee "$ROOT/P80_MAP_UNIT_DYNAMIC_STATE_AUDIT.log"

printf '\n== Native -> unsigned IPA hardened P80 pipeline ==\n'
exec "$NATIVE/BUILD_FROM_CODEX_MAC.sh"
