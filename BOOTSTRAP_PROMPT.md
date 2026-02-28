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
3. Ask me what my preferences are (communication style, tool preferences, commit
   conventions, anything I want Claude to always know) so we can fill in
   global-state.md together
4. Ask me if I want to set up backup (see below) — I will need to provide a
   private GitHub repo URL before you can proceed with that step
```

---

## What happens

The install script will:
- Create `~/.claude/memory/` and `~/.claude/memory/journal/`
- Install `~/.claude/global-state.md` (your persistent index)
- Install `~/.claude/hooks/check-global-state.sh` (warns when state is stale)
- Install `/init-memory` as a Claude Code slash command
- Register the hook in `~/.claude/settings.json`

After the paste, Claude will walk you through filling in your preferences. From
then on, every session in every repo will start with full context of where you
left off. You don't need to do anything special — just open Claude Code and
start working. Claude reads the state files automatically.

---

## Setting up backup (recommended)

Your memory files live locally at `~/.claude/`. If you want them backed up and
synced across machines, you need to provide a **private GitHub repo**.

**You must create this repo yourself** — Claude cannot do it for you.

Steps:
1. Go to github.com/new
2. Create a **private** repo (name it anything — e.g. `claude-memory`)
3. Copy the repo URL (SSH preferred: `git@github.com:you/claude-memory.git`)
4. Tell Claude: *"Set up backup using <your-repo-url>"*

Claude will then run:
```
bash ~/.claude/memory-kit/backup/setup.sh <your-repo-url>
```

This will:
- Clone your backup repo to `~/.claude-backup/`
- Do an initial sync of your memory files
- Install hooks that automatically restore at session start and push at session end

After that, your memory is backed up silently on every session — no manual steps.

---

## Per-repo initialization

In any repo you work in, run:
```
/init-memory
```

Claude will create `.claude/state.md`, fix your `.gitignore`, and register the
repo in your global index.

---

## Source

https://github.com/leizerowicz/ai-memory-kit

The one-line installer always pulls from the `main` branch. To install a specific version:
```
# To install a specific version:
AIMK_VERSION=v1.0.0 bash <(curl -fsSL https://raw.githubusercontent.com/leizerowicz/ai-memory-kit/main/install.sh)
```
