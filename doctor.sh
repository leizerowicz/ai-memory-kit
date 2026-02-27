#!/usr/bin/env bash
# AI Memory Kit — Doctor
# Validates that the memory system is correctly installed and functioning.
# Usage: bash doctor.sh [--verbose]

set -euo pipefail

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET}  $1"; }
err()  { echo -e "${RED}✗${RESET} $1"; }
info() { echo "  $1"; }

ISSUES=0

check_hook_registered() {
    echo ""
    echo "Hook registration"
    local SETTINGS="$HOME/.claude/settings.json"
    if [ ! -f "$SETTINGS" ]; then
        err "settings.json not found — hook is not registered"
        info "Run: bash setup.sh --tool claude-code"
        ((ISSUES++))
        return
    fi
    if grep -q "check-global-state" "$SETTINGS" 2>/dev/null; then
        ok "SessionStart hook registered in settings.json"
    else
        err "Hook not registered in settings.json"
        info "Re-run setup.sh to merge the hook"
        ((ISSUES++))
    fi

    if [ -f "$HOME/.claude/hooks/check-global-state.sh" ]; then
        ok "check-global-state.sh exists"
    else
        err "check-global-state.sh not found at ~/.claude/hooks/"
        ((ISSUES++))
    fi
}

check_global_state() {
    echo ""
    echo "Global state file"
    local GLOBAL="$HOME/.claude/global-state.md"
    if [ ! -f "$GLOBAL" ]; then
        err "global-state.md not found at $GLOBAL"
        info "Run: bash setup.sh --tool claude-code"
        ((ISSUES++))
        return
    fi
    ok "global-state.md exists"

    # Check if it was updated recently
    local LAST_UPDATED
    LAST_UPDATED=$(grep -m1 '^Last updated:' "$GLOBAL" 2>/dev/null | sed 's/^Last updated: *//' || echo "")
    if [ -n "$LAST_UPDATED" ]; then
        if [[ "$LAST_UPDATED" < "$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null || echo '0000-00-00')" ]]; then
            warn "global-state.md last updated $LAST_UPDATED (>7 days ago)"
        else
            ok "global-state.md updated $LAST_UPDATED"
        fi
    else
        warn "global-state.md has no 'Last updated:' line"
    fi
}

check_backup() {
    echo ""
    echo "Backup status"
    local LAST_PUSH="$HOME/.claude/.backup-last-push"
    local LAST_ERROR="$HOME/.claude/.backup-last-error"

    if [ ! -f "$HOME/.claude-backup/.git/config" ] 2>/dev/null && [ ! -f "$LAST_PUSH" ]; then
        info "Backup not configured (optional — run backup/setup.sh <repo-url> to enable)"
        return
    fi

    if [ -f "$LAST_ERROR" ]; then
        warn "Backup: last push FAILED"
        info "$(cat "$LAST_ERROR")"
        ((ISSUES++))
    elif [ -f "$LAST_PUSH" ]; then
        local PUSH_TIME
        PUSH_TIME=$(cat "$LAST_PUSH")
        ok "Backup: last push $PUSH_TIME"
    else
        warn "Backup configured but no push record found"
    fi
}

scan_repos() {
    echo ""
    echo "Repo state files"
    local SCAN_ROOTS="${AI_MEMORY_SCAN_ROOTS:-$HOME/repos $HOME/code $HOME/dev $HOME/projects}"
    local FOUND=0

    for root in $SCAN_ROOTS; do
        [ -d "$root" ] || continue
        while IFS= read -r state_file; do
            FOUND=$((FOUND + 1))
            local rel="${state_file#$HOME/}"
            local repo_name="${rel%/.claude/team-state.md}"
            repo_name="${repo_name%/.claude/state.md}"
            local LAST_UPDATED
            LAST_UPDATED=$(grep -m1 '^Last updated:' "$state_file" 2>/dev/null | sed 's/^Last updated: *//' || echo "unknown")
            ok "$repo_name (updated $LAST_UPDATED)"
        done < <(find "$root" \( -path '*/.claude/state.md' -o -path '*/.claude/team-state.md' \) 2>/dev/null | sort)
    done

    if [ "$FOUND" -eq 0 ]; then
        info "No repos with state.md found in: $SCAN_ROOTS"
        info "Run /init-memory in a repo to initialize it"
    fi
}

check_memory_files() {
    echo ""
    echo "Memory files"
    local MEMORY_DIR="$HOME/.claude/memory"
    if [ ! -d "$MEMORY_DIR" ]; then
        warn "Memory directory not found: $MEMORY_DIR"
        return
    fi

    local COUNT=0
    while IFS= read -r f; do
        COUNT=$((COUNT + 1))
        local SIZE
        SIZE=$(wc -c < "$f" 2>/dev/null || echo 0)
        local SIZE_KB=$((SIZE / 1024))
        local FNAME
        FNAME=$(basename "$f")
        if [ "$SIZE" -gt 8192 ]; then
            warn "$FNAME (${SIZE_KB}KB) — exceeds recommended 8KB; consider summarizing"
        else
            [ "$VERBOSE" = true ] && ok "$FNAME (${SIZE_KB}KB)"
        fi
    done < <(find "$MEMORY_DIR" -name '*.md' -not -path '*/journal/*' 2>/dev/null | sort)

    local JOURNAL_DIR="$MEMORY_DIR/journal"
    if [ -d "$JOURNAL_DIR" ]; then
        local JOURNAL_COUNT
        JOURNAL_COUNT=$(find "$JOURNAL_DIR" -name '*.md' 2>/dev/null | wc -l)
        ok "Journal: $JOURNAL_COUNT entries"
    fi

    [ "$COUNT" -gt 0 ] && ok "$COUNT memory file(s) found" || info "No memory files yet"
}

# Run checks
echo ""
echo "AI Memory Kit — Doctor"
echo "══════════════════════"

check_hook_registered
check_global_state
check_backup
check_memory_files
scan_repos

echo ""
echo "══════════════════════"
if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}All checks passed${RESET}"
else
    echo -e "${YELLOW}$ISSUES issue(s) found${RESET}"
    exit 1
fi
