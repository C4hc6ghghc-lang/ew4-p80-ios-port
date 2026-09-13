#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
NATIVE="$ROOT/SOURCE_NATIVE/EW4_iOS_NativePort"

printf '\n== Current mature SOURCE_LEAN freeze ==\n'
python3 "$ROOT/VERIFY_SOURCE_LEAN_FROZEN.py"

printf '\n== EW4 cross-project scope guard ==\n'
python3 "$ROOT/VERIFY_EW4_SCOPE_GUARD.py"

printf '\n== Current native IPA preflight ==\n'
python3 "$NATIVE/Tools/native_ipa_preflight.py" --report "$NATIVE/Docs/NATIVE_IPA_PREFLIGHT_REPORT.json"

printf '\n== Xcode candidate static handoff gate ==\n'
python3 "$NATIVE/Tools/xcode_candidate_static_gate.py" --report "$NATIVE/Docs/XCODE_CANDIDATE_STATIC_GATE.json"

printf '\n== P80 map/unit/dynamic-state evidence gate ==\n'
python3 "$ROOT/P80_MAP_UNIT_DYNAMIC_STATE_AUDIT.py" | tee "$ROOT/P80_MAP_UNIT_DYNAMIC_STATE_AUDIT.log"

printf '\n== Script syntax ==\n'
bash -n "$ROOT/BUILD_FROM_CODEX_MAC.sh" "$NATIVE/BUILD_FROM_CODEX_MAC.sh" "$NATIVE/Tools/build_unsigned_ipa.sh"
python3 -m py_compile \
  "$ROOT/VERIFY_SOURCE_LEAN_FROZEN.py" \
  "$ROOT/VERIFY_EW4_SCOPE_GUARD.py" \
  "$NATIVE/Tools/native_ipa_preflight.py" \
  "$NATIVE/Tools/verify_ipa_payload.py" \
  "$NATIVE/Tools/xcode_candidate_static_gate.py" \
  "$ROOT/P80_MAP_UNIT_DYNAMIC_STATE_AUDIT.py"
find "$ROOT" -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true

echo 'P80_PACKAGE_PREFLIGHT_PASS'
