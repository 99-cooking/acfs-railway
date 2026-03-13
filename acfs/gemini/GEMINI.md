# ACFS Environment — Gemini Instructions

> This environment has 50+ pre-installed tools. Use them directly — no installation needed.

## Rules

1. **Never delete files** without explicit user permission
2. **Never run destructive commands** (`git reset --hard`, `rm -rf`, etc.) without explicit approval
3. Run quality checks (`cargo check`, `go vet`, `bun typecheck`) after code changes
4. Run tests before committing

## Installed Tools

### AI Agents
| Command | Description |
|---------|-------------|
| `cc` | Claude Code (Anthropic) |
| `cod` | Codex CLI (OpenAI) |
| `gmi` | Gemini CLI (Google) |

### Code Quality
| Command | Description |
|---------|-------------|
| `ubs <files>` | Ultimate Bug Scanner — run before every commit |
| `sg` | ast-grep — AST-aware code search and rewrite |
| `rg` | ripgrep — fast text search |

### Project Management
| Command | Description |
|---------|-------------|
| `br ready` | Beads — show unblocked issues ready to work |
| `br create --title="..." --type=task` | Create new issue |
| `bv --robot-triage` | Graph-aware triage — ranked recommendations |
| `bv --robot-next` | Just the single top pick |

### Safety
| Command | Description |
|---------|-------------|
| `dcg` | Destructive Command Guard — blocks dangerous operations |
| `slb` | Two-person rule for dangerous commands |

### Session Management
| Command | Description |
|---------|-------------|
| `ntm spawn` | Create multi-agent tmux session |
| `ntm list` | List active sessions |
| `ntm send` | Send prompt to agents |

### Utilities
| Command | Description |
|---------|-------------|
| `cass` | Search agent session history |
| `cm recall` | Search past sessions for patterns |
| `ru sync` | Sync all managed repos |
| `caam` | Switch between AI provider accounts |

### Modern CLI
`bat` (cat), `fd` (find), `eza` (ls), `delta` (diff), `fzf` (fuzzy find), `zoxide` (cd), `lazygit`, `atuin` (history)

## Multi-Agent Coordination

Use **MCP Agent Mail** for inter-agent messaging and file reservations. Claude Code has it wired as an MCP server.

Workflow: `br ready` → pick issue → `file_reservation_paths()` → work → `br close` → release reservations

## Tmux

Prefix: `Ctrl-a` (not Ctrl-b). Navigate panes: `Ctrl-a h/j/k/l`. Zoom: `Ctrl-a z`.

## CRITICAL: bv flags

**Always use `--robot-*` flags with bv.** Bare `bv` launches an interactive TUI that blocks your session.
