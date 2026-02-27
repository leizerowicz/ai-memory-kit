---
description: Initialize the AI Memory Kit for the current repo. Creates .claude/state.md, ensures correct .gitignore entries, appends session protocol to CLAUDE.md, and registers the repo in the global index. Safe to run multiple times (idempotent).
---

# Initialize Memory System for Current Repo

Run these steps in order. Skip any step that's already done (this command is idempotent).

## Step 1: Detect Context

- Determine the current working directory
- Check if it's a git repo (`ls .git` or `git rev-parse --show-toplevel`)
- Read `~/.claude/global-state.md` to check if this repo is already registered

## Step 2: Create `.claude/state.md` (if missing)

If `.claude/state.md` does not exist, create it:

```markdown
# [Repo Name] — Project State

Last updated: [today's date]

## Current Branch
[run `git branch --show-current`]

## Current Status
[Ask the user what this repo is about, or infer from CLAUDE.md / README]

## What's Next
[Leave blank for now]

## Gotchas
[Leave blank for now]
```

## Step 3: Fix `.gitignore`

Check `.gitignore`. Ensure these lines are present:

```
.claude/state.md
.claude/settings.local.json
.claude/memory.db
```

**Do NOT add `.claude/` as a whole directory.** That breaks skills and commands. Only add the specific files above.

If any of those lines are missing, append them. If `.claude/` (as a directory) is already in `.gitignore`, remove it and replace with the three file-level entries above.

## Step 4: Append Session Protocol to CLAUDE.md

Read the repo's `CLAUDE.md`. If it does NOT already contain "Session State Protocol", append this:

```markdown

## Session State Protocol

**At session start (REQUIRED):**
1. Read `~/.claude/global-state.md` — preferences, active projects, memory file manifest
2. Read `.claude/state.md` in this repo — branch, progress, next steps, gotchas
3. Check the Memory Files table in global-state.md — load any `~/.claude/memory/` files relevant to this session's topic

**At session end (when user says stop/done/pause/tomorrow):**
1. Update `.claude/state.md` with: what's done, what's next, blockers, gotchas
2. Update the project's row in `~/.claude/global-state.md` Active Projects table
3. If significant new cross-repo context was created (patterns, strategies, decisions), create or update a file in `~/.claude/memory/` and add it to the Memory Files manifest in global-state.md

**Do NOT use ruvector/claude-flow memory CLI for state storage.** Use plain markdown files only.
```

If `CLAUDE.md` doesn't exist, create a minimal one with the repo name as a heading and the block above.

## Step 5: Register in Global Index

Read `~/.claude/global-state.md`. If the current repo is NOT in the Active Projects table, add a row:

```
| [Project Name] | [full repo path] | New — just initialized | TBD |
```

Add the repo's state file to the State Files table if missing:

```
| `[full path]/.claude/state.md` | What this repo covers |
```

## Step 6: Report

Tell the user:
- `.claude/state.md` — created or already existed
- `.gitignore` — updated or already correct
- `CLAUDE.md` — protocol appended or already present
- `global-state.md` — repo registered or already listed
