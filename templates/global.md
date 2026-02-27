# Global State — Index

Last updated: YYYY-MM-DD

## Preferences
- [Working style preferences — e.g. "direct communication, no filler"]
- [Tool preferences — e.g. "always use TypeScript strict mode"]
- [Commit style — e.g. "imperative mood, explain why not what"]
- [Review preference — e.g. "draft comms to me first before sending externally"]

## Active Projects

| Project | Repo | Status | Next |
|---------|------|--------|------|
| Example Project | ~/repos/org/repo | Brief current status | Concrete next action |

## Memory Files (load on demand)

Load these from `~/.ai-memory/memory/` when the session topic matches:

| File | When to load | Summary |
|------|-------------|---------|
| `example-topic.md` | Keywords that trigger loading | One-line summary of what's inside |

## State Files (per-repo)

| Location | Covers |
|----------|--------|
| `~/.ai-memory/state.md` | Admin work, non-repo tasks |
| `~/repos/org/repo/.ai-memory/state.md` | What this repo is about |

## Session Protocol

**Start:**
1. Read this file + the repo's `.ai-memory/state.md`
2. Check Memory Files table — load any that match this session's topic
3. Summarize current state, then ask: **"What's the goal for this session? What does success look like?"**

**Mid-session drift check:** If work diverges from the stated goal, flag it gently and ask whether to stay the course or pivot.

**End (on "stop" / "done" / "pause" / "tomorrow"):**
1. Update this file's Active Projects row for the current repo
2. Update the repo's `.ai-memory/state.md`
3. Create/update topic memory files for any significant new cross-repo context
4. Append to `~/.ai-memory/memory/journal/YYYY-MM-DD.md`
5. Confirm: **"State saved. Say 'let's continue' next time."**
