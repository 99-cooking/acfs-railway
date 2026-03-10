# ACFS Railway Template 🚀

> One-click deploy of the [Agentic Coding Flywheel Setup](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup) on Railway.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/template/acfs-railway?referralCode=99cooking)

## What You Get

A browser-accessible terminal (via ttyd) with the full ACFS stack pre-installed:

**AI Coding Agents:**
- Claude Code (Anthropic)
- Codex CLI (OpenAI)
- Gemini CLI (Google)

**Language Runtimes:**
- Bun, Node.js (LTS), Python (uv), Rust, Go

**Modern CLI Tools:**
- bat, fd, ripgrep, eza, delta, fzf, zoxide, lazygit
- zsh + Oh My Zsh + Powerlevel10k

**Dicklesworthstone Stack:**
- NTM (Neural Task Manager)
- SLB (Super Linter/Bug finder)
- Beads, CM, CASS

## Setup

1. Click **Deploy on Railway** above
2. Set your API keys as environment variables:
   - `ANTHROPIC_API_KEY` — for Claude Code
   - `OPENAI_API_KEY` — for Codex CLI
   - `GEMINI_API_KEY` — for Gemini CLI
3. Railway will build and deploy — open the generated URL for a web terminal

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | For Claude | Anthropic API key |
| `OPENAI_API_KEY` | For Codex | OpenAI API key |
| `GEMINI_API_KEY` | For Gemini | Google AI API key |

## Credits

Based on [agentic_coding_flywheel_setup](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup) by [@Dicklesworthstone](https://github.com/Dicklesworthstone).

Containerized for Railway by [99 Cooking](https://99cook.ing).
