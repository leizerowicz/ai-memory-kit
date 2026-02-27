# AI Memory Kit
## Persistent Cross-Session Context for AI Coding Assistants

> **Tool-agnostic.** Works with Claude Code, Cursor, Copilot, or any AI assistant that reads files. See `specializations/` for tool-specific setup.

---

## The Problem

AI coding assistants have no memory between sessions. Every conversation starts from zero. You re-explain the project, re-establish conventions, re-describe where you left off. The AI re-discovers things it already learned last time.

This kit solves that with **plain markdown files** that your AI reads at the start of every session. No databases, no proprietary formats, no vendor lock-in — just text files you own and can read yourself.

---

## How It Works

Your AI reads a small set of markdown files at session start to reconstruct context. At session end, it updates those files with what changed. The next session picks up exactly where you left off.

### The Three-File Pattern

```
~/.ai-memory/
  global.md              # Thin index — always loaded. Preferences, project table, file manifest.
  state.md               # Admin/non-repo notes (decisions, emails, misc tasks)
  memory/                # Topic files — loaded on demand when the session topic matches
    <topic>.md
    journal/
      YYYY-MM-DD.md      # Daily log, append-only

<repo>/.ai-memory/
  state.md               # Per-repo: branch, status, next steps, gotchas
```

**The index stays small** (under 80 lines). Detail lives in `memory/` files and is loaded only when relevant. This keeps every session fast and focused.

---

## Quick Start

```bash
# Clone or download this kit, then:
bash setup.sh
```

The setup script will:
- Create the memory directory structure
- Install template files
- Install your chosen tool's specialization
- Register any hooks or system prompt fragments

Then pick up your tool-specific README in `specializations/`.

---

## Manual Setup

If you prefer to set up by hand:

### 1. Create the directory structure

```bash
mkdir -p ~/.ai-memory/memory/journal
```

### 2. Copy and fill in the global index

```bash
cp templates/global.md ~/.ai-memory/global.md
# Edit it with your name, preferences, and initial projects
```

### 3. Add the session protocol to your AI tool

Each tool has a different mechanism. See `specializations/` for your tool:

| Tool | Specialization |
|------|---------------|
| Claude Code | `specializations/claude-code/` |
| Cursor | `specializations/cursor/` |
| Any (manual system prompt) | `specializations/generic/` |

### 4. Initialize each repo

Copy `templates/repo-state.md` to `<repo>/.ai-memory/state.md` and fill it in. Or use the `/init-memory` command if your tool supports custom commands (see specialization).

---

## The Protocol

### Session Start

Your AI will:
1. Read `~/.ai-memory/global.md` (always)
2. Read the current repo's `.ai-memory/state.md` (always)
3. Check the Memory Files table in `global.md` — load any topic files that match the session
4. Say: **"Resuming [project]: [summary of current state]"**
5. Ask: **"What's the goal for this session? What does success look like?"**

### Mid-Session

If the session drifts from the stated goal, the AI flags it:

> *"Quick check — we set out to [goal]. This feels like [tangent]. Stay the course or pivot?"*

### Session End

When you say "stop", "done", "pause", "wrap up", or "tomorrow":
1. AI updates `.ai-memory/state.md` in the current repo
2. AI updates the Active Projects row in `~/.ai-memory/global.md`
3. AI creates/updates any relevant topic memory files
4. AI appends to `~/.ai-memory/memory/journal/YYYY-MM-DD.md`
5. AI confirms: **"State saved. Say 'let's continue' next time."**

---

## File Templates

All templates are in `templates/`. See them for copy-paste-ready starting points:

| Template | Purpose |
|----------|---------|
| `templates/global.md` | Starting `~/.ai-memory/global.md` |
| `templates/repo-state.md` | Starting `.ai-memory/state.md` for a repo |
| `templates/memory-file.md` | Starting point for a topic memory file |
| `templates/session-protocol-fragment.md` | The protocol block to inject into your AI tool |

---

## What to Store

**Good memory file candidates:**
- Decisions that span multiple repos or sessions
- Negotiation strategies, vendor context, key email threads
- Architectural patterns your team has settled on
- Solutions to recurring problems
- Cross-repo conventions

**Don't store:**
- Things already in the codebase (code is the source of truth)
- Single-session temporary state
- Anything that duplicates what's in a project README or CLAUDE.md

---

## Journal Format

The journal is a daily append-only log. Each entry follows this structure:

```markdown
## [Project or context] — [Brief title]
**Why:** [The stated goal for this session]
**What:** [Bullet list of what was actually done]
**Outcome:** [Did we hit the goal? Key deliverables]
**On track?:** [Focused or did we drift? What caused drift?]
**Lessons:** [Worth remembering cross-session]
```

Multiple sessions per day just append more blocks to the same file.

---

## Specializations

The core protocol is tool-agnostic. Specializations handle tool-specific wiring:

- **How to tell the AI what to read** (CLAUDE.md, .cursorrules, system prompt injection)
- **How to register session hooks** (for tools that support them)
- **How to add custom commands** (e.g. `/init-memory`)

See `specializations/<tool>/README.md` for your tool.

---

## Contributing a Specialization

To add support for a new tool:
1. Create `specializations/<tool-name>/README.md` following the pattern in `specializations/claude-code/README.md`
2. Include any config files, hook scripts, or command files needed
3. Document the install steps clearly — assume no prior context

---

## Critical Rules

1. **Always read state files at session start.** They're plain files — they cannot fail.
2. **Always update state files at session end.** Edit in place; don't append new sections.
3. **Keep the global index small** (under 80 lines). Detail goes in `memory/` files.
4. **Per-repo state stays focused** on that repo. Cross-repo context goes in topic files.
5. **Don't gitignore your AI tool's config directory as a whole.** Only ignore local-only files (state.md, secrets). Commands, skills, and settings should be tracked.
