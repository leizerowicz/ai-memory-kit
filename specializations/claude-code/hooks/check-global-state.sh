#!/usr/bin/env bash
# AI Memory Kit — Anti-Drift Hook for Claude Code
# Runs on SessionStart. Warns when a repo's .claude/state.md is newer than
# ~/.claude/global-state.md, indicating the global Active Projects table
# may be stale for this repo.
#
# Install: copy to ~/.claude/hooks/check-global-state.sh
# Register: add to ~/.claude/settings.json (see settings.json in this directory)

set -euo pipefail

GLOBAL_STATE="$HOME/.claude/global-state.md"
REPO_STATE=".claude/state.md"

# Extract "Last updated: YYYY-MM-DD" from a file
get_date() {
    grep -m1 '^Last updated:' "$1" 2>/dev/null | sed 's/^Last updated: *//; s/\r//' || echo ""
}

# --- Check current repo ---
if [ -f "$REPO_STATE" ]; then
    REPO_DATE=$(get_date "$REPO_STATE")
    GLOBAL_DATE=$(get_date "$GLOBAL_STATE")

    if [ -n "$REPO_DATE" ] && [ -n "$GLOBAL_DATE" ]; then
        if [[ "$REPO_DATE" > "$GLOBAL_DATE" ]]; then
            REPO_NAME=$(basename "$(git -C . rev-parse --show-toplevel 2>/dev/null || pwd)")
            echo "⚠️  STALE GLOBAL STATE: ${REPO_NAME}/.claude/state.md was updated ${REPO_DATE} but ~/.claude/global-state.md was last updated ${GLOBAL_DATE}."
            echo "ACTION REQUIRED: Update the Active Projects row for '${REPO_NAME}' in ~/.claude/global-state.md before proceeding."
        fi
    fi
fi

# --- Scan all repos for broader staleness ---
# Scan roots: colon-separated list of directories to search for repo state files.
# Override by setting AI_MEMORY_SCAN_ROOTS in your environment (colon-separated).
# Default: $HOME/repos:$HOME/code:$HOME/dev:$HOME/projects
IFS=: read -ra SCAN_ROOT_ARRAY <<< "${AI_MEMORY_SCAN_ROOTS:-$HOME/repos:$HOME/code:$HOME/dev:$HOME/projects}"

STALE_REPOS=()
GLOBAL_DATE=$(get_date "$GLOBAL_STATE")

if [ -n "$GLOBAL_DATE" ]; then
    for root in "${SCAN_ROOT_ARRAY[@]}"; do
        [ -d "$root" ] || continue
        while IFS= read -r state_file; do
            FILE_DATE=$(get_date "$state_file")
            if [ -n "$FILE_DATE" ] && [[ "$FILE_DATE" > "$GLOBAL_DATE" ]]; then
                rel="${state_file#$HOME/}"
                repo_name="${rel%/.claude/state.md}"
                STALE_REPOS+=("$repo_name ($FILE_DATE)")
            fi
        done < <(find "$root" -path '*/.claude/state.md' -not -path '*/node_modules/*' 2>/dev/null)
    done

    if [ ${#STALE_REPOS[@]} -gt 0 ]; then
        echo ""
        echo "📋 Other repos with state newer than global-state.md (${GLOBAL_DATE}):"
        for r in "${STALE_REPOS[@]}"; do
            echo "   - $r"
        done
        echo "Consider updating their Active Projects rows when convenient."
    fi
fi
