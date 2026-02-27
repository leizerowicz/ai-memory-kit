# Bootstrap Prompt

Copy and paste the block below into a new Claude Code session. That's it.

---

```
Please set up the AI Memory Kit for my Claude Code environment.

Run this command:
curl -fsSL https://raw.githubusercontent.com/leizerowicz/ai-memory-kit/main/install.sh | bash

Once it completes:
1. Tell me what was installed and what still needs to be configured
2. Run /init-memory to initialize memory for the current repo
3. Ask me what my preferences are (communication style, tool preferences, commit conventions, anything I want Claude to always know) so we can fill in global-state.md together
```

---

## What happens

The install script will:
- Create `~/.claude/memory/` and `~/.claude/memory/journal/`
- Install `~/.claude/global-state.md` (your persistent index — edit this with your preferences)
- Install `~/.claude/hooks/check-global-state.sh` (warns you when state is stale)
- Install `/init-memory` as a Claude Code slash command
- Register the hook in `~/.claude/settings.json`

After the paste, Claude will walk you through filling in your preferences. From then on, every session in every repo will start with full context of where you left off. You don't need to do anything special — just open Claude Code and start working. Claude reads the state files automatically.

## Per-repo initialization

In any repo you work in, run:
```
/init-memory
```

Claude will create `.claude/state.md`, fix your `.gitignore`, and register the repo in your global index.

## Source

https://github.com/leizerowicz/ai-memory-kit
