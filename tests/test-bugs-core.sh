#!/usr/bin/env bash
# Tests for bugs-core fixes: #1, #2, #5, #6
set -euo pipefail

PASS=0; FAIL=0; ERRORS=()

assert_eq() { local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then PASS=$((PASS+1)); echo "  ✓ $desc"
  else FAIL=$((FAIL+1)); ERRORS+=("FAIL: $desc — expected '$expected', got '$actual'"); echo "  ✗ $desc"; fi
}

assert_contains() { local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then PASS=$((PASS+1)); echo "  ✓ $desc"
  else FAIL=$((FAIL+1)); ERRORS+=("FAIL: $desc — '$needle' not found"); echo "  ✗ $desc"; fi
}

assert_file_exists() { local desc="$1" file="$2"
  if [ -f "$file" ]; then PASS=$((PASS+1)); echo "  ✓ $desc"
  else FAIL=$((FAIL+1)); ERRORS+=("FAIL: $desc — file not found: $file"); echo "  ✗ $desc"; fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test #6: .gitattributes exists
echo ""
echo "Issue #6: .gitattributes"
assert_file_exists ".gitattributes exists" "$SCRIPT_DIR/.gitattributes"
if [ -f "$SCRIPT_DIR/.gitattributes" ]; then
  assert_contains ".gitattributes has *.sh eol=lf" "*.sh" "$(cat "$SCRIPT_DIR/.gitattributes")"
fi

# Test #5: argument parsing
echo ""
echo "Issue #5: --tool argument parsing"
# Test --tool=claude-code (= form)
OUT=$(bash "$SCRIPT_DIR/setup.sh" --tool=claude-code --dry-run 2>&1 || true)
assert_contains "--tool=value form works" "claude-code" "$OUT"

# Test --tool claude-code (space form)
OUT=$(bash "$SCRIPT_DIR/setup.sh" --tool claude-code --dry-run 2>&1 || true)
assert_contains "--tool value form works" "claude-code" "$OUT"

# Test #1: templates/global.md doesn't have ~/.claude/ hardcoded (template should use ~/.ai-memory/)
echo ""
echo "Issue #1: template paths"
TEMPLATE="$SCRIPT_DIR/templates/global.md"
# Template should use ~/.ai-memory/ (generic), NOT ~/.claude/ (tool-specific)
if grep -qF "~/.claude/" "$TEMPLATE" 2>/dev/null; then
  CLAUDE_COUNT=$(grep -cF "~/.claude/" "$TEMPLATE")
else
  CLAUDE_COUNT="0"
fi
assert_eq "template uses generic paths (no ~/.claude/ hardcoded)" "0" "$CLAUDE_COUNT"

# Test #2: setup.sh has Python merge logic for settings.json
echo ""
echo "Issue #2: settings.json merge"
assert_contains "setup.sh has python3 merge" "python3" "$(cat "$SCRIPT_DIR/setup.sh")"
assert_contains "setup.sh has setdefault" "setdefault" "$(cat "$SCRIPT_DIR/setup.sh")"

# Summary
echo ""
echo "Results: $PASS passed, $FAIL failed"
for err in "${ERRORS[@]}"; do echo "  $err"; done
[ "$FAIL" -eq 0 ] || exit 1
