
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
