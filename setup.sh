#!/usr/bin/env bash
# AI Memory Kit — Setup Script
# Installs the memory system for your AI coding assistant.
# Safe to re-run (idempotent). Backs up existing files before modifying.
#
# Usage:
#   bash setup.sh                    # Interactive — prompts for tool choice
#   bash setup.sh --tool claude-code # Non-interactive
#   bash setup.sh --tool cursor
#   bash setup.sh --tool generic
#   bash setup.sh --dry-run          # Preview changes without modifying files
#   bash setup.sh --help             # Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL=""
DRY_RUN=false
REPO_DIR=""

# ── Argument parsing ──────────────────────────────────────────────────────────

usage() {
    cat <<USAGE
Usage: bash setup.sh [OPTIONS]

Options:
  --tool=TOOL     Specify tool without prompt (claude-code, cursor, generic)
  --tool TOOL     Same as above (space-separated form)
  --repo=PATH     Install per-repo rule into PATH (Cursor only)
  --repo PATH     Same as above (space-separated form)
  --update        Update mode: overwrite hook scripts and commands (memory files untouched)
  --dry-run       Preview what would be installed without modifying files
  --help          Show this help message

Examples:
  bash setup.sh
  bash setup.sh --tool claude-code
  bash setup.sh --tool=cursor --repo .
  bash setup.sh --tool claude-code --update --dry-run
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool=*) TOOL="${1#--tool=}"; shift ;;
        --tool)
            if [ -z "${2:-}" ]; then
                echo "Error: --tool requires a value (claude-code, cursor, or generic)"
                exit 1
            fi
            TOOL="$2"; shift 2 ;;
        --repo=*) REPO_DIR="$(cd "${1#--repo=}" 2>/dev/null && pwd || echo "")"; shift ;;
        --repo)
            if [ -z "${2:-}" ]; then
                echo "Error: --repo requires a path"
                exit 1
            fi
            REPO_DIR="$(cd "$2" 2>/dev/null && pwd || echo "")"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help) usage; exit 0 ;;
        *) shift ;;
    esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

log()    { echo -e "${GREEN}✓${RESET} $1"; }
warn()   { echo -e "${YELLOW}⚠${RESET}  $1"; }
info()   { echo "  $1"; }
header() { echo ""; echo -e "${GREEN}── $1 ──${RESET}"; }

backup_if_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$file" "$backup"
        warn "Backed up existing $file → $backup"
    fi
}

run() {
    if [ "$DRY_RUN" = true ]; then
        info "[dry-run] $*"
    else
        "$@"
    fi
}

append_if_missing() {
    local needle="$1"
    local content="$2"
    local file="$3"
    if ! grep -qF "$needle" "$file" 2>/dev/null; then
        echo "$content" >> "$file"
        log "Appended to $file"
    else
        info "Already present in $file — skipped"
    fi
}

# ── Tool selection ─────────────────────────────────────────────────────────────

if [ -z "$TOOL" ]; then
    echo ""
    echo "AI Memory Kit — Setup"
    echo "─────────────────────"
    echo "Which AI tool are you setting up for?"
    echo "  1) Claude Code"
    echo "  2) Cursor"
    echo "  3) Generic (system prompt / manual)"
    echo ""
    read -rp "Enter choice [1-3]: " choice
    case "$choice" in
        1) TOOL="claude-code" ;;
        2) TOOL="cursor" ;;
        3) TOOL="generic" ;;
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
fi

SPEC_DIR="$SCRIPT_DIR/specializations/$TOOL"
if [ ! -d "$SPEC_DIR" ]; then
    echo -e "${RED}Error:${RESET} No specialization found for '$TOOL' at $SPEC_DIR"
    echo "Available: $(ls "$SCRIPT_DIR/specializations/")"
    exit 1
fi

echo ""
echo "Installing AI Memory Kit for: $TOOL"
[ "$DRY_RUN" = true ] && warn "Dry-run mode — no files will be modified"

# ── Tool-specific config ───────────────────────────────────────────────────────

case "$TOOL" in
    claude-code)
        MEMORY_DIR="$HOME/.claude"
        MEMORY_SUBDIR="$HOME/.claude/memory"
        GLOBAL_STATE="$HOME/.claude/global-state.md"
        ADMIN_STATE="$HOME/.claude/state.md"
        GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
        ;;
    cursor)
        MEMORY_DIR="$HOME/.ai-memory"
        MEMORY_SUBDIR="$HOME/.ai-memory/memory"
        GLOBAL_STATE="$HOME/.ai-memory/global.md"
        ADMIN_STATE="$HOME/.ai-memory/state.md"
        GLOBAL_CLAUDE_MD=""  # No global instructions file for Cursor
        ;;
    generic)
        MEMORY_DIR="$HOME/.ai-memory"
        MEMORY_SUBDIR="$HOME/.ai-memory/memory"
        GLOBAL_STATE="$HOME/.ai-memory/global.md"
        ADMIN_STATE="$HOME/.ai-memory/state.md"
        GLOBAL_CLAUDE_MD=""
        ;;
esac

# ── Step 1: Directories ────────────────────────────────────────────────────────

header "Creating directories"

run mkdir -p "$MEMORY_SUBDIR/journal"
log "Memory directories: $MEMORY_SUBDIR/journal"

if [ "$TOOL" = "claude-code" ]; then
    run mkdir -p "$HOME/.claude/hooks"
    run mkdir -p "$HOME/.claude/commands"
    log "Claude Code hooks and commands directories"
fi

# ── Step 2: Global state file ─────────────────────────────────────────────────

header "Global state file"

if [ ! -f "$GLOBAL_STATE" ]; then
    if [ "$TOOL" = "claude-code" ]; then
        if [ "$DRY_RUN" = false ]; then
            sed \
                -e 's|~/.ai-memory/|~/.claude/|g' \
                -e 's|\.ai-memory/state\.md|.claude/state.md|g' \
                "$SCRIPT_DIR/templates/global.md" > "$GLOBAL_STATE"
        else
            info "[dry-run] Would sed (path substitution) templates/global.md > $GLOBAL_STATE"
        fi
    else
        run cp "$SCRIPT_DIR/templates/global.md" "$GLOBAL_STATE"
    fi
    log "Created $GLOBAL_STATE"
    warn "Edit $GLOBAL_STATE to add your name, preferences, and projects"
else
    info "Already exists: $GLOBAL_STATE — skipped"
fi

# ── Step 3: Admin state file ──────────────────────────────────────────────────

header "Admin state file"

if [ ! -f "$ADMIN_STATE" ]; then
    run cp "$SCRIPT_DIR/templates/repo-state.md" "$ADMIN_STATE"
    log "Created $ADMIN_STATE"
else
    info "Already exists: $ADMIN_STATE — skipped"
fi

# ── Step 4: Tool-specific files ───────────────────────────────────────────────

header "Tool-specific files ($TOOL)"

case "$TOOL" in
    claude-code)
        # Global CLAUDE.md fragment
        if [ -n "$GLOBAL_CLAUDE_MD" ]; then
            touch "$GLOBAL_CLAUDE_MD"
            append_if_missing "Session State Protocol" \
                "$(cat "$SPEC_DIR/CLAUDE.md-global-fragment.md")" \
                "$GLOBAL_CLAUDE_MD"
        fi

        # Hook script
        HOOK_DEST="$HOME/.claude/hooks/check-global-state.sh"
        if [ ! -f "$HOOK_DEST" ]; then
            run cp "$SPEC_DIR/hooks/check-global-state.sh" "$HOOK_DEST"
            run chmod +x "$HOOK_DEST"
            log "Installed hook: $HOOK_DEST"
        else
            info "Hook already exists: $HOOK_DEST — skipped"
        fi

        # init-memory command
        CMD_DEST="$HOME/.claude/commands/init-memory.md"
        if [ ! -f "$CMD_DEST" ]; then
            run cp "$SPEC_DIR/commands/init-memory.md" "$CMD_DEST"
            log "Installed command: /init-memory"
        else
            info "/init-memory command already exists — skipped"
        fi

        # settings.json — merge hook, don't overwrite
        SETTINGS="$HOME/.claude/settings.json"
        HOOK_CMD="bash ~/.claude/hooks/check-global-state.sh"

        if [ ! -f "$SETTINGS" ]; then
            run cp "$SPEC_DIR/settings.json" "$SETTINGS"
            log "Created $SETTINGS with hook registration"
        else
            if ! grep -q "check-global-state" "$SETTINGS" 2>/dev/null; then
                # Merge hook into existing settings.json using Python
                if [ "$DRY_RUN" = false ]; then
                    # Write to temp file first (atomic write)
                    TMP_SETTINGS="$(mktemp)"
                    if python3 - "$SETTINGS" "$HOOK_CMD" "$TMP_SETTINGS" <<'PYEOF' 2>/dev/null; then
import json, sys
settings_path, hook_cmd, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(settings_path) as f:
        settings = json.load(f)
except (json.JSONDecodeError, IOError):
    sys.exit(1)
hooks = settings.setdefault("hooks", {})
session_start = hooks.setdefault("SessionStart", [])
if not isinstance(session_start, list):
    sys.exit(1)
hook_entry = {"type": "command", "command": hook_cmd}
if not any(h.get("command") == hook_cmd for h in session_start if isinstance(h, dict)):
    session_start.append(hook_entry)
with open(out_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF
                        mv "$TMP_SETTINGS" "$SETTINGS"
                        log "Merged SessionStart hook into existing $SETTINGS"
                    else
                        rm -f "$TMP_SETTINGS"
                        warn "Could not auto-merge hook into $SETTINGS (malformed JSON or python3 unavailable)."
                        warn "Manually add the SessionStart hook from: $SPEC_DIR/settings.json"
                    fi
                else
                    info "[dry-run] Would merge hook into $SETTINGS"
                fi
            else
                info "Hook already registered in settings.json — skipped"
            fi
        fi
        ;;

    cursor)
        # Global rules
        run mkdir -p "$HOME/.cursor/rules"
        GLOBAL_RULE="$HOME/.cursor/rules/ai-memory.mdc"
        if [ ! -f "$GLOBAL_RULE" ] || [ "${UPDATE:-false}" = true ]; then
            run cp "$SPEC_DIR/global-rule.mdc" "$GLOBAL_RULE"
            log "Installed global Cursor rule: $GLOBAL_RULE"
        else
            info "Global Cursor rule already exists — skipped"
        fi

        # Per-repo rule (if --repo was passed)
        if [ -n "${REPO_DIR:-}" ]; then
            if [ -d "$REPO_DIR" ]; then
                RULE_DIR="$REPO_DIR/.cursor/rules"
                run mkdir -p "$RULE_DIR"
                if [ ! -f "$RULE_DIR/memory.mdc" ] || [ "${UPDATE:-false}" = true ]; then
                    run cp "$SPEC_DIR/repo-rule.mdc" "$RULE_DIR/memory.mdc"
                    log "Installed repo rule: $RULE_DIR/memory.mdc"
                    warn "Edit $RULE_DIR/memory.mdc to add repo name and initial status"
                else
                    info "Repo rule already exists — skipped"
                fi
            else
                warn "--repo path not found or not a directory: $REPO_DIR"
            fi
        fi
        ;;

    generic)
        info "Generic setup complete. See $SPEC_DIR/README.md for system prompt instructions."
        ;;
esac

# ── Step 5: Summary ───────────────────────────────────────────────────────────

header "Done"

echo ""
echo "Memory kit installed for $TOOL."
echo ""
echo "Next steps:"
echo "  1. Edit $GLOBAL_STATE with your preferences and projects"

if [ "$TOOL" = "claude-code" ]; then
    echo "  2. Open a repo and run /init-memory to set it up"
    echo "  3. Start a Claude Code session — it will load your state automatically"
elif [ "$TOOL" = "cursor" ]; then
    echo "  2. Open a repo and run: bash setup.sh --tool cursor --repo <path>"
    echo "  3. Start a Cursor session — the global rule loads your state automatically"
    echo "  4. See specializations/cursor/README.md for full documentation"
else
    echo "  2. Add the session protocol to your tool's system prompt"
    echo "     See: specializations/generic/README.md"
fi

echo ""
echo "  Full documentation: README.md"
echo ""
