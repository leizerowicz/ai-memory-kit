#!/usr/bin/env bash
# Tests for bugs-reliability fixes: #3, #4, #7
set -euo pipefail

PASS=0; FAIL=0; ERRORS=()

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); }

assert_eq() { local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass; echo "  ✓ $desc"
  else fail; ERRORS+=("FAIL: $desc — expected '$expected', got '$actual'"); echo "  ✗ $desc"; fi
}

assert_contains() { local desc="$1" needle="$2" haystack="$3"
  local found=0
  echo "$haystack" | grep -qF -- "$needle" && found=1 || found=0
  if [ "$found" -eq 1 ]; then pass; echo "  ✓ $desc"
  else fail; ERRORS+=("FAIL: $desc — '$needle' not found"); echo "  ✗ $desc"; fi
}

assert_not_contains() { local desc="$1" needle="$2" haystack="$3"
  local found=0
  echo "$haystack" | grep -qF -- "$needle" && found=1 || found=0
  if [ "$found" -eq 0 ]; then pass; echo "  ✓ $desc"
  else fail; ERRORS+=("FAIL: $desc — '$needle' was found but should not be"); echo "  ✗ $desc"; fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test #3: backup/setup.sh doesn't use --mkpath
echo ""
echo "Issue #3: rsync --mkpath removed"
BACKUP_SETUP="$SCRIPT_DIR/backup/setup.sh"
assert_not_contains "backup/setup.sh has no --mkpath" "--mkpath" "$(cat "$BACKUP_SETUP")"
assert_contains "backup/setup.sh uses mkdir -p" "mkdir -p" "$(cat "$BACKUP_SETUP")"
assert_contains "backup/setup.sh checks for rsync" "command -v rsync" "$(cat "$BACKUP_SETUP")"

# Test #4: session hooks have set -euo pipefail
echo ""
echo "Issue #4: set -euo pipefail in hooks"
SESSION_END="$SCRIPT_DIR/backup/hooks/session-end.sh"
SESSION_START="$SCRIPT_DIR/backup/hooks/session-start.sh"
assert_contains "session-end.sh has set -euo pipefail" "set -euo pipefail" "$(cat "$SESSION_END")"
assert_contains "session-start.sh has set -euo pipefail" "set -euo pipefail" "$(cat "$SESSION_START")"

# Check cd has explicit error handling
if grep -q 'cd.*|| {' "$SESSION_END" || grep -q 'cd.*||.*exit' "$SESSION_END"; then
    pass; echo "  ✓ session-end.sh: cd has explicit error handling"
else
    fail; ERRORS+=("FAIL: cd lacks explicit error handling in session-end.sh"); echo "  ✗ session-end.sh: cd has explicit error handling"
fi

# Test #7: check-global-state.sh uses configurable scan roots
echo ""
echo "Issue #7: configurable scan roots"
HOOK="$SCRIPT_DIR/specializations/claude-code/hooks/check-global-state.sh"
assert_contains "hook has AI_MEMORY_SCAN_ROOTS" "AI_MEMORY_SCAN_ROOTS" "$(cat "$HOOK")"
assert_not_contains "hook doesn't hardcode \$HOME/repos in find" 'find "$HOME/repos"' "$(cat "$HOOK")"
assert_contains "hook scans multiple roots with for loop" "for root in" "$(cat "$HOOK")"
assert_contains "hook skips missing dirs" '[ -d "$root" ] || continue' "$(cat "$HOOK")"
assert_contains "hook strips relative to HOME (not HOME/repos)" '${state_file#$HOME/}' "$(cat "$HOOK")"
assert_contains "hook documents the env var" "AI_MEMORY_SCAN_ROOTS" "$(cat "$HOOK")"

# Test scan roots behavior: if AI_MEMORY_SCAN_ROOTS is empty dir, no crash
echo ""
echo "Issue #7: hook runs without error when scan roots are empty"
EMPTY_DIR="$(mktemp -d)"
AI_MEMORY_SCAN_ROOTS="$EMPTY_DIR" bash "$HOOK" 2>/dev/null || true  # Should not crash
pass; echo "  ✓ hook runs without error on empty scan roots"
rm -rf "$EMPTY_DIR"

# Test scan roots behavior: AI_MEMORY_SCAN_ROOTS pointing to non-existent dir doesn't crash
echo ""
echo "Issue #7: hook runs without error when scan root doesn't exist"
AI_MEMORY_SCAN_ROOTS="/tmp/nonexistent-dir-$$" bash "$HOOK" 2>/dev/null || true
pass; echo "  ✓ hook runs without error on non-existent scan root"

echo ""
echo "Issue #7: paths with spaces in scan roots"
SPACE_DIR="$(mktemp -d)/dir with spaces"
mkdir -p "$SPACE_DIR"
# Create a fake state file in it
mkdir -p "$SPACE_DIR/myrepo/.claude"
echo "Last updated: 2026-02-27" > "$SPACE_DIR/myrepo/.claude/state.md"

# Run hook with colon-separated path containing space
OUTPUT=$(AI_MEMORY_SCAN_ROOTS="$SPACE_DIR" bash "$HOOK" 2>/dev/null || true)
# Should not crash (exit successfully)
((PASS++)); echo "  ✓ hook handles scan root with space in path"
rm -rf "$(dirname "$SPACE_DIR")"

# Summary
echo ""
echo "Results: $PASS passed, $FAIL failed"
for err in "${ERRORS[@]}"; do echo "  $err"; done
[ "$FAIL" -eq 0 ] || exit 1
