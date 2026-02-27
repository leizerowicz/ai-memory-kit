#!/usr/bin/env bash
# AI Memory Kit — Backup Restore Hook
# Runs at session start. Pulls latest from backup repo, then syncs to ~/.claude/
# Silently no-ops if backup isn't configured or git isn't available.

MEMORY_DIR="$HOME/.claude"
BACKUP_DIR_FILE="$MEMORY_DIR/.backup-dir"

[ -f "$BACKUP_DIR_FILE" ] || exit 0
BACKUP_DIR="$(cat "$BACKUP_DIR_FILE")"
[ -d "$BACKUP_DIR/.git" ] || exit 0
command -v git &>/dev/null || exit 0

# Pull latest (silently — don't block session start)
git -C "$BACKUP_DIR" pull --quiet --ff-only 2>/dev/null || true

# Restore: sync backup -> ~/.claude/
rsync -a --update \
    "$BACKUP_DIR/global-state.md" \
    "$MEMORY_DIR/" 2>/dev/null || true

rsync -a --update \
    "$BACKUP_DIR/state.md" \
    "$MEMORY_DIR/" 2>/dev/null || true

if [ -d "$BACKUP_DIR/memory" ]; then
    rsync -a --update "$BACKUP_DIR/memory/" "$MEMORY_DIR/memory/" 2>/dev/null || true
fi
