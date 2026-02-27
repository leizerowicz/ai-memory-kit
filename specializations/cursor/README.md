# Cursor Specialization

> Status: Stub. Contributions welcome.

## How Cursor Differs

Cursor uses `.cursorrules` at the repo root (or a `rules` block in `.cursor/config`) as persistent instructions that get injected into the AI context. There is no native hook system for session start/end.

## Wiring the Protocol

### Per-Repo

Create `.cursorrules` at the repo root (or append to it if it exists):

```
cat ../../templates/session-protocol-fragment.md >> .cursorrules
```

Update the memory directory paths in the fragment from `~/.ai-memory/` to `~/.cursor-memory/` (or whichever directory you choose).

### Global

Cursor does not currently have a global system prompt file equivalent to Claude Code's `~/.claude/CLAUDE.md`. Options:
1. Add the global protocol to every repo's `.cursorrules` (repetitive but reliable)
2. Use a Cursor Rule that references a shared file (if your Cursor version supports it)

## Memory Directory

Since Cursor doesn't have a `~/.cursor/` convention, use `~/.ai-memory/` as your memory root so it's tool-neutral. Adjust all paths in the session protocol fragment accordingly.

## Limitations

- No native hook support means session-end updates must be triggered manually ("done, update state files")
- No custom slash commands — use natural language ("initialize memory for this repo")

## Contributing

If you've built a working Cursor integration, please add:
- The exact `.cursorrules` content that works
- Any workarounds for the missing hook system
- Instructions for the per-repo setup
