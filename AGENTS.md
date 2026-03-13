# AGENTS.md — ACFS Railway

> Guidelines for AI coding agents working on this project.

---

## RULE 0 — Override Prerogative

If the user tells you to do something that contradicts these guidelines, **do what the user says**.

---

## RULE 1 — No File Deletion

**Never delete a file or folder without explicit permission.** Always ask first. No exceptions.

---

## No Destructive Git Commands

**Forbidden without explicit user approval:** `git reset --hard`, `git clean -fd`, `rm -rf`, force push.

Use non-destructive alternatives first (`git stash`, `git diff`, backups). If a destructive command is needed, state the exact command, list what it affects, and wait for confirmation.

---

## Project Overview

This is a **containerized fork of ACFS** that deploys on Railway. The original ACFS is a bash installer for Ubuntu VPS environments — this fork packages everything into a Docker image with a browser-accessible terminal.

### Components

| Component | Location | What It Does |
|-----------|----------|--------------|
| **Dockerfile** | `Dockerfile` | The core — builds Ubuntu image with 50+ tools |
| **Session Manager** | `session-manager/server.js` | Node.js dashboard routing browser tabs to tmux/ttyd sessions |
| **Railway Config** | `railway.toml`, `railway.json` | Deployment configuration |
| **Shell Config** | `acfs/zsh/acfs.zshrc` | zsh config with aliases, tool integrations |
| **Tmux Config** | `acfs/tmux/tmux.conf` | Tmux config (Ctrl-a prefix, vim keys) |
| **Claude Config** | `acfs/claude/settings.json` | Claude Code settings for the container |
| **Claude Hooks** | `.claude/hooks/` | Claude Code hooks (copied into image) |
| **Container AGENTS.md** | `acfs/AGENTS.md` | Agent instructions inside the container |

---

## How It Works

The Dockerfile installs everything in phases:
1. Base system packages (apt)
2. Go + Rust toolchains
3. Modern CLI tools (bat, fd, ripgrep, eza, delta, fzf, zoxide, lazygit)
4. Language runtimes (Bun, Node.js, Python/uv)
5. AI coding agents (Claude, Codex, Gemini, OpenCode)
6. Cloud CLIs (Railway, Wrangler, Supabase, Vercel, Vault)
7. Dicklesworthstone stack — Go tools (NTM, SLB, BV, CAAM)
8. Dicklesworthstone stack — Rust tools (Beads, CASS, DCG, RCH, etc.)
9. Dicklesworthstone stack — Script/TS/Python tools (Agent Mail, UBS, CM, RU, etc.)
10. Shell setup (Oh My Zsh, Powerlevel10k, plugins)
11. Config deployment (zshrc, tmux.conf, AGENTS.md, Claude hooks)

The `session-manager/server.js` runs as the entrypoint, serving a dashboard and routing browser tabs to individual tmux sessions via ttyd.

---

## Code Editing Rules

- **No file proliferation** — revise existing files in place, don't create `_v2` variants
- **After code changes, verify:**
  ```bash
  docker build -t acfs-railway .
  ```

---

## Git

- **Default branch:** `main`
