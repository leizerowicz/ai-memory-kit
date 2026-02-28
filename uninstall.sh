#!/usr/bin/env bash
# AI Memory Kit — Uninstaller
# Removes installed hooks, commands, and settings fragments.
# NEVER deletes your memory content (global-state.md, memory/ directory).
#
# Usage: bash uninstall.sh [--tool claude-code]

set -euo pipefail

TOOL="${1:-}"
[[ "${1:-}" == "--tool" ]] && TOOL="${2:-}"
[[ "${1:-}" == "--tool="* ]] && TOOL="${1#--tool=}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
log()  { echo -e "${GREEN}✓${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET}  $1"; }
info() { echo "  $1"; }
err()  { echo -e "${RED}✗${RESET} $1"; exit 1; }

echo ""
echo "AI Memory Kit — Uninstall"
echo ""
warn "This will remove hooks, commands, and settings fragments."
warn "Your memory files (global-state.md, memory/) will NOT be deleted."
echo ""
read -rp "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# Remove hook
HOOK="$HOME/.claude/hooks/check-global-state.sh"
if [ -f "$HOOK" ]; then
    rm "$HOOK"
    log "Removed $HOOK"
fi

# Remove commands
CMD="$HOME/.claude/commands/init-memory.md"
if [ -f "$CMD" ]; then
    rm "$CMD"
    log "Removed $CMD"
fi

DOCTOR_CMD="$HOME/.claude/commands/doctor.md"
if [ -f "$DOCTOR_CMD" ]; then
    rm "$DOCTOR_CMD"
    log "Removed $DOCTOR_CMD"
fi

# Remove hook from settings.json
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ] && grep -q "check-global-state" "$SETTINGS" 2>/dev/null; then
    python3 - "$SETTINGS" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    settings = json.load(f)
hooks = settings.get("hooks", {})
session_start = hooks.get("SessionStart", [])
hooks["SessionStart"] = [h for h in session_start if "check-global-state" not in h.get("command", "")]
if not hooks["SessionStart"]:
    del hooks["SessionStart"]
if not hooks:
    del settings["hooks"]
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF
    log "Removed hook from $SETTINGS"
fi

# Remove installed kit copy
KIT_DEST="$HOME/.claude/memory-kit"
if [ -d "$KIT_DEST" ]; then
    rm -rf "$KIT_DEST"
    log "Removed $KIT_DEST"
fi

echo ""
log "Uninstall complete."
echo ""
info "Your memory files are preserved:"
info "  ~/.claude/global-state.md"
info "  ~/.claude/memory/"
info ""
info "To reinstall: curl -fsSL https://raw.githubusercontent.com/leizerowicz/ai-memory-kit/main/install.sh | bash"
