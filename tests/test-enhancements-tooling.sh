#!/usr/bin/env bash
# AI Memory Kit — Tooling Enhancements Test Suite
# Tests for enhancements #8 (Cursor integration), #15 (backup visibility),
# and #16 (versioned installer).
#
# Usage: bash tests/test-enhancements-tooling.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

pass() { echo -e "${GREEN}PASS${RESET} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}FAIL${RESET} $1"; FAIL=$((FAIL + 1)); }

assert_file_exists() {
    local file="$1"
    local label="${2:-$file}"
    if [ -f "$file" ]; then
        pass "$label exists"
    else
        fail "$label does not exist (expected: $file)"
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local label="${3:-contains '$pattern'}"
    if grep -qF -- "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label (pattern not found in $file)"
    fi
}

assert_file_contains_regex() {
    local file="$1"
    local pattern="$2"
    local label="${3:-matches '$pattern'}"
    if grep -qE "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label (regex not matched in $file)"
    fi
}

echo ""
echo "AI Memory Kit — Tooling Enhancements Test Suite"
echo "================================================"
echo ""

# ── Enhancement #8: Cursor Integration ────────────────────────────────────────

echo "Enhancement #8: Cursor specialization"
echo "--------------------------------------"

CURSOR_SPEC="$ROOT_DIR/specializations/cursor"

assert_file_exists "$CURSOR_SPEC/global-rule.mdc" \
    "specializations/cursor/global-rule.mdc"

assert_file_contains "$CURSOR_SPEC/global-rule.mdc" "alwaysApply: true" \
    "global-rule.mdc has alwaysApply: true"

assert_file_contains "$CURSOR_SPEC/global-rule.mdc" "Session Start (REQUIRED)" \
    "global-rule.mdc has session-start instructions"

assert_file_contains "$CURSOR_SPEC/global-rule.mdc" "Session End Triggers" \
    "global-rule.mdc has session-end triggers"

assert_file_contains "$CURSOR_SPEC/global-rule.mdc" "~/.ai-memory/global.md" \
    "global-rule.mdc references ~/.ai-memory/global.md"

assert_file_exists "$CURSOR_SPEC/repo-rule.mdc" \
    "specializations/cursor/repo-rule.mdc"

assert_file_contains "$CURSOR_SPEC/repo-rule.mdc" "alwaysApply: true" \
    "repo-rule.mdc has alwaysApply: true"

assert_file_contains "$CURSOR_SPEC/repo-rule.mdc" "REPO_NAME" \
    "repo-rule.mdc has REPO_NAME placeholder"

assert_file_exists "$CURSOR_SPEC/README.md" \
    "specializations/cursor/README.md"

assert_file_contains "$CURSOR_SPEC/README.md" "global-rule.mdc" \
    "README.md references global-rule.mdc"

assert_file_contains "$CURSOR_SPEC/README.md" "repo-rule.mdc" \
    "README.md references repo-rule.mdc"

assert_file_contains "$CURSOR_SPEC/README.md" "done for today" \
    "README.md documents session-end trigger phrases"

# setup.sh supports --repo argument
assert_file_contains "$ROOT_DIR/setup.sh" "--repo" \
    "setup.sh supports --repo argument"

assert_file_contains "$ROOT_DIR/setup.sh" "global-rule.mdc" \
    "setup.sh installs global-rule.mdc for cursor"

assert_file_contains "$ROOT_DIR/setup.sh" "repo-rule.mdc" \
    "setup.sh installs repo-rule.mdc for cursor"

echo ""

# ── Enhancement #15: Backup Failure Visibility ────────────────────────────────

echo "Enhancement #15: Backup failure visibility"
echo "------------------------------------------"

SESSION_END="$ROOT_DIR/backup/hooks/session-end.sh"
SESSION_START="$ROOT_DIR/backup/hooks/session-start.sh"

assert_file_exists "$SESSION_END" "backup/hooks/session-end.sh"
assert_file_exists "$SESSION_START" "backup/hooks/session-start.sh"

assert_file_contains "$SESSION_END" ".backup-last-push" \
    "session-end.sh writes .backup-last-push on success"

assert_file_contains "$SESSION_END" ".backup-last-error" \
    "session-end.sh writes .backup-last-error on failure"

assert_file_contains "$SESSION_END" "Backup push failed" \
    "session-end.sh shows error message on push failure"

assert_file_contains "$SESSION_END" "exit 1" \
    "session-end.sh exits non-zero on push failure"

# Ensure 2>/dev/null suppression is removed from the push command
if grep -qE "git push.*2>/dev/null" "$SESSION_END" 2>/dev/null; then
    fail "session-end.sh still suppresses push errors with 2>/dev/null"
else
    pass "session-end.sh does not suppress push errors with 2>/dev/null"
fi

assert_file_contains "$SESSION_START" ".backup-last-error" \
    "session-start.sh checks for .backup-last-error"

assert_file_contains "$SESSION_START" "last push FAILED" \
    "session-start.sh warns when last push failed"

echo ""

# ── Enhancement #16: Versioned Installer ─────────────────────────────────────

echo "Enhancement #16: Versioned installer"
echo "-------------------------------------"

INSTALLER="$ROOT_DIR/install.sh"

assert_file_exists "$INSTALLER" "install.sh"

assert_file_contains "$INSTALLER" "AIMK_VERSION" \
    "install.sh supports AIMK_VERSION env var"

assert_file_contains "$INSTALLER" 'VERSION="${AIMK_VERSION:-main}"' \
    "install.sh defaults VERSION to main"

assert_file_contains "$INSTALLER" "refs/tags/" \
    "install.sh uses tag URL for versioned installs"

assert_file_contains "$INSTALLER" "refs/heads/main" \
    "install.sh uses branch URL for main"

assert_file_contains "$INSTALLER" 'setup.sh" ]; then' \
    "install.sh verifies archive structure"

assert_file_contains "$INSTALLER" "Error: download failed" \
    "install.sh shows error on bad download"

assert_file_contains "$INSTALLER" "trap cleanup EXIT" \
    "install.sh cleans up temp dir on exit"

assert_file_exists "$ROOT_DIR/VERSIONS.md" \
    "VERSIONS.md exists"

assert_file_contains "$ROOT_DIR/VERSIONS.md" "AIMK_VERSION" \
    "VERSIONS.md documents AIMK_VERSION usage"

assert_file_contains "$ROOT_DIR/VERSIONS.md" "git tag -a" \
    "VERSIONS.md documents tagging process"

assert_file_contains "$ROOT_DIR/BOOTSTRAP_PROMPT.md" "AIMK_VERSION" \
    "BOOTSTRAP_PROMPT.md documents version pinning"

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}All tests passed.${RESET}"
    exit 0
else
    echo -e "${RED}$FAIL test(s) failed.${RESET}"
    exit 1
fi
