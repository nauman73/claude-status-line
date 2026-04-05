#!/usr/bin/env bash
# Manual verification script for cwd truncation feature
# Pauses after each test so you can inspect the output

SCRIPT="$(cd "$(dirname "$0")" && pwd)/statusline-command.sh"
LONG_PATH="/home/user/very/deeply/nested/project/directory/structure/src/components"
LONG_JSON="{\"workspace\":{\"current_dir\":\"$LONG_PATH\"},\"model\":{\"display_name\":\"Opus 4.6\"}}"

pause() {
  echo ""
}

# Helper: run the script with overridden constants (uses bash builtins only)
# Usage: run_with <MAX_CWD_LENGTH> <CWD_TRUNC_POS> <json>
run_with() {
  local max="$1" pos="$2" json="$3"
  echo "$json" | bash -c "
    MAX_CWD_LENGTH=$max
    CWD_TRUNC_POS=$pos
    source /dev/stdin <<'INNER'
$(tail -n +5 "$SCRIPT")
INNER
  "
}

echo "=========================================="
echo "  CWD Truncation Verification Tests"
echo "=========================================="

echo ""
echo "--- Test 1: Short path (no truncation expected) ---"
echo "  MAX=40, POS=20, path=/short"
echo '{"workspace":{"current_dir":"/short"},"model":{"display_name":"Opus 4.6"}}' | bash "$SCRIPT"
echo ""
pause

echo "--- Test 2: Long path (truncated with … in the middle) ---"
echo "  MAX=40, POS=20, path=$LONG_PATH"
echo "$LONG_JSON" | bash "$SCRIPT"
echo ""
pause

echo "--- Test 3: Path exactly at limit (40 chars, no truncation) ---"
echo "  MAX=40, POS=20, path=/home/user/projects/exactly-forty-ch"
echo '{"workspace":{"current_dir":"/home/user/projects/exactly-forty-ch"},"model":{"display_name":"Opus 4.6"}}' | bash "$SCRIPT"
echo ""
pause

echo "--- Test 4: Empty input (no output, exit 0) ---"
echo "  Expecting blank line below:"
echo '' | bash "$SCRIPT"
echo "(end)"
pause

echo "--- Test 5: Model only, no cwd (falls back to pwd) ---"
echo '{"model":{"display_name":"Opus 4.6"}}' | bash "$SCRIPT"
echo ""
pause

echo "--- Test 6: Full payload (all segments visible) ---"
echo '{"session_id":"abc12345-def","model":{"display_name":"Opus 4.6"},"workspace":{"current_dir":"/tmp"},"context_window":{"remaining_percentage":80},"rate_limits":{"five_hour":{"used_percentage":10},"seven_day":{"used_percentage":25}}}' | bash "$SCRIPT"
echo ""
pause

echo "--- Test 7: NO_COLOR (no ANSI escapes) ---"
echo "$LONG_JSON" | NO_COLOR=1 bash "$SCRIPT"
echo ""
pause

echo "--- Test 8: TERM=dumb (no ANSI escapes) ---"
echo "$LONG_JSON" | TERM=dumb bash "$SCRIPT"
echo ""
pause

echo "=========================================="
echo "  Edge Case Tests (override constants)"
echo "=========================================="
echo ""
echo "  These tests create temp copies of the script"
echo "  with modified constants."
echo ""

# For edge case tests, create a temp copy and patch the constants on lines 5-6
run_patched() {
  local max="$1" pos="$2" json="$3"
  local tmp
  tmp=$(mktemp)
  cp "$SCRIPT" "$tmp"
  sed -i "5s/.*/MAX_CWD_LENGTH=$max/" "$tmp"
  sed -i "6s/.*/CWD_TRUNC_POS=$pos/" "$tmp"
  echo "$json" | NO_COLOR=1 bash "$tmp"
  rm -f "$tmp"
}

echo "--- Test 9: MAX_CWD_LENGTH=0 (truncation disabled) ---"
echo "  Expecting full path, no truncation"
run_patched 0 20 "$LONG_JSON"
echo ""
pause

echo "--- Test 10: CWD_TRUNC_POS=0 (all budget to tail) ---"
echo "  Expecting: …<tail of path>"
run_patched 40 0 "$LONG_JSON"
echo ""
pause

echo "--- Test 11: CWD_TRUNC_POS=50 > MAX=40 (clamped to 39) ---"
echo "  Expecting: <head of path>…"
run_patched 40 50 "$LONG_JSON"
echo ""
pause

echo "--- Test 12: MAX_CWD_LENGTH=1, CWD_TRUNC_POS=0 (tail=0, skip) ---"
echo "  Expecting full path, truncation skipped"
run_patched 1 0 '{"workspace":{"current_dir":"/home/user/projects"},"model":{"display_name":"Opus 4.6"}}'
echo ""
pause

echo "--- Test 13: MAX_CWD_LENGTH=2, CWD_TRUNC_POS=5 (clamped to 1, tail=0, skip) ---"
echo "  Expecting full path, truncation skipped"
run_patched 2 5 '{"workspace":{"current_dir":"/home/user/projects"},"model":{"display_name":"Opus 4.6"}}'
echo ""
pause

echo "--- Test 14: CWD_TRUNC_POS=-5 (clamped to 0) ---"
echo "  Expecting: …<tail of path>"
run_patched 40 -5 "$LONG_JSON"
echo ""
pause

echo "=========================================="
echo "  All tests complete!"
echo "=========================================="
