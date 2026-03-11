# ============================================================
# ACFS Railway — Agentic Coding Flywheel on Railway
# Browser-accessible coding terminal with AI agents pre-installed
# The comprehensive edition: 50+ tools, all batteries included
# ============================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    NEEDRESTART_MODE=a \
    TERM=xterm-256color \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/zsh

# Configurable user and hostname (override via Railway env vars)
ENV ACFS_USER=dev \
    ACFS_HOSTNAME=acfs

# ============================================================
# Phase 1: Base system packages
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates unzip tar xz-utils jq build-essential \
    gnupg wget sudo zsh locales procps htop vim nano tmux tree openssh-client \
    libssl-dev pkg-config libsqlite3-dev \
    python3 python3-pip python3-venv \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================================
# Phase 2: Go + Rust (needed for stack tools)
# ============================================================
RUN curl -fsSL "https://go.dev/dl/go1.23.6.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:$PATH"

ENV RUSTUP_HOME="/opt/rustup" \
    CARGO_HOME="/opt/cargo"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/opt/cargo/bin:$PATH"

ENV GOPATH="/opt/gopath"

# ============================================================
# Phase 3: Modern CLI tools
# ============================================================
RUN curl -fsSL "https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/bat-v0.24.0-x86_64-unknown-linux-gnu/bat /usr/local/bin/ && rm -rf /tmp/bat-*

RUN curl -fsSL "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/fd-v10.2.0-x86_64-unknown-linux-gnu/fd /usr/local/bin/ && rm -rf /tmp/fd-*

RUN curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/ripgrep-14.1.1-x86_64-unknown-linux-musl/rg /usr/local/bin/ && rm -rf /tmp/ripgrep-*

RUN curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/eza /usr/local/bin/ && rm -rf /tmp/eza*

RUN curl -fsSL "https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/delta-0.18.2-x86_64-unknown-linux-gnu/delta /usr/local/bin/ && rm -rf /tmp/delta-*

RUN curl -fsSL "https://github.com/junegunn/fzf/releases/download/v0.57.0/fzf-0.57.0-linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin/

RUN curl -fsSL "https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.6/zoxide-0.9.6-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/local/bin/ zoxide

RUN curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v0.44.1/lazygit_0.44.1_Linux_x86_64.tar.gz" \
    | tar -xz -C /usr/local/bin/ lazygit

# ast-grep (syntax-aware code search, needed by UBS)
RUN cargo install ast-grep --locked 2>/dev/null \
    && cp /opt/cargo/bin/sg /usr/local/bin/ 2>/dev/null \
    || echo "ast-grep: build skipped"

# atuin (shell history with search)
RUN curl -fsSL "https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/atuin-*/atuin /usr/local/bin/ && rm -rf /tmp/atuin-* \
    || echo "atuin: install skipped"

# ============================================================
# Phase 4: Language runtimes
# ============================================================

# Bun
ENV BUN_INSTALL="/opt/bun"
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="$BUN_INSTALL/bin:$PATH"

# uv (Python)
RUN curl -LsSf https://astral.sh/uv/install.sh | CARGO_HOME=/opt/uv sh
RUN mv /root/.local/bin/uv /usr/local/bin/ 2>/dev/null || mv /opt/uv/bin/uv /usr/local/bin/ 2>/dev/null || true
RUN mv /root/.local/bin/uvx /usr/local/bin/ 2>/dev/null || true

# Node.js LTS (via n — installs to /usr/local)
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o /usr/local/bin/n \
    && chmod +x /usr/local/bin/n \
    && n lts

# ============================================================
# Phase 5: AI Coding Agents
# ============================================================
RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g @openai/codex 2>/dev/null || echo "codex: not yet available via npm"
RUN npm install -g @google/gemini-cli 2>/dev/null || echo "gemini: not yet available via npm"

# OpenCode (terminal AI agent)
RUN curl -fsSL "https://github.com/opencode-ai/opencode/releases/latest/download/opencode-linux-x86_64.tar.gz" \
    | tar -xz -C /usr/local/bin/ opencode

# oh-my-openagent (OpenCode enhancer — multi-model agent harness)
RUN npm install -g oh-my-opencode 2>/dev/null || \
    (git clone --depth 1 -b dev https://github.com/code-yeongyu/oh-my-openagent.git /tmp/omo \
    && cd /tmp/omo && bun install && bun run build 2>/dev/null \
    && npm install -g . \
    && cd / && rm -rf /tmp/omo) \
    || echo "oh-my-openagent: install skipped"

# ============================================================
# Phase 6: Cloud CLIs
# ============================================================
RUN npm install -g wrangler 2>/dev/null || echo "wrangler: install skipped"
RUN npm install -g supabase 2>/dev/null || echo "supabase: install skipped"
RUN npm install -g vercel 2>/dev/null || echo "vercel: install skipped"

# HashiCorp Vault
RUN curl -fsSL "https://releases.hashicorp.com/vault/1.17.2/vault_1.17.2_linux_amd64.zip" -o /tmp/vault.zip \
    && unzip -q /tmp/vault.zip -d /usr/local/bin/ && rm /tmp/vault.zip \
    || echo "vault: install skipped"

# ============================================================
# Phase 7: Dicklesworthstone Stack — Go tools
# ============================================================

# NTM — Named Tmux Manager (agent cockpit)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/ntm.git /tmp/ntm \
    && cd /tmp/ntm && go build -o /usr/local/bin/ntm ./cmd/ntm 2>/dev/null \
    || (cd /tmp/ntm && go build -o /usr/local/bin/ntm . 2>/dev/null) \
    && cd / && rm -rf /tmp/ntm) \
    || echo "ntm: build skipped"

# SLB — Simultaneous Launch Button (two-person rule)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/simultaneous_launch_button.git /tmp/slb \
    && cd /tmp/slb && go build -o /usr/local/bin/slb ./cmd/slb 2>/dev/null \
    || (cd /tmp/slb && go build -o /usr/local/bin/slb . 2>/dev/null) \
    && cd / && rm -rf /tmp/slb) \
    || echo "slb: build skipped"

# Beads Viewer — TUI for beads (Go)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/beads_viewer.git /tmp/bv \
    && cd /tmp/bv && go build -o /usr/local/bin/bv ./cmd/bv 2>/dev/null \
    || (cd /tmp/bv && go build -o /usr/local/bin/bv . 2>/dev/null) \
    && cd / && rm -rf /tmp/bv) \
    || echo "beads_viewer: build skipped"

# CAAM — Agent auth switching (Go)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/caam.git /tmp/caam \
    && cd /tmp/caam && go build -o /usr/local/bin/caam ./cmd/caam 2>/dev/null \
    || (cd /tmp/caam && go build -o /usr/local/bin/caam . 2>/dev/null) \
    && cd / && rm -rf /tmp/caam) \
    || echo "caam: build skipped"

# Copy any go-installed binaries
RUN cp /opt/gopath/bin/* /usr/local/bin/ 2>/dev/null || true

# ============================================================
# Phase 8: Dicklesworthstone Stack — Rust tools
# ============================================================

# Beads — graph-aware issue tracker
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/beads_rust.git /tmp/beads \
    && cd /tmp/beads && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable -name "beads*" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/beads) \
    || echo "beads: build skipped"

# Meta Skill — semantic search knowledge base
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/meta_skill.git /tmp/ms \
    && cd /tmp/ms && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/ms) \
    || echo "meta_skill: build skipped"

# Process Triage — zombie process killer
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/process_triage.git /tmp/pt \
    && cd /tmp/pt && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/pt) \
    || echo "process_triage: build skipped"

# CASS — agent session history search
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/coding_agent_session_search.git /tmp/cass \
    && cd /tmp/cass && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/cass) \
    || echo "cass: build skipped"

# DCG — Destructive Command Guard
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/dcg.git /tmp/dcg \
    && cd /tmp/dcg && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/dcg) \
    || echo "dcg: build skipped"

# RCH — Remote Compilation Helper
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/rch.git /tmp/rch \
    && cd /tmp/rch && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/rch) \
    || echo "rch: build skipped"

# XF — ultra-fast Twitter archive search (Tantivy)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/xf.git /tmp/xf \
    && cd /tmp/xf && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/xf) \
    || echo "xf: build skipped"

# Toon Rust — token-optimized notation
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/toon_rust.git /tmp/tru \
    && cd /tmp/tru && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/tru) \
    || echo "toon_rust: build skipped"

# RANO — network observer for AI CLIs
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/rano.git /tmp/rano \
    && cd /tmp/rano && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/rano) \
    || echo "rano: build skipped"

# MDWB — markdown web browser
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/markdown_web_browser.git /tmp/mdwb \
    && cd /tmp/mdwb && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/mdwb) \
    || echo "mdwb: build skipped"

# Rust Proxy — transparent proxy routing
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/rust_proxy.git /tmp/rp \
    && cd /tmp/rp && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/rp) \
    || echo "rust_proxy: build skipped"

# AADC — ASCII diagram corrector
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/aadc.git /tmp/aadc \
    && cd /tmp/aadc && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/aadc) \
    || echo "aadc: build skipped"

# CAUT — coding agent usage tracker
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/coding_agent_usage_tracker.git /tmp/caut \
    && cd /tmp/caut && cargo build --release \
    && find target/release -maxdepth 1 -type f -executable ! -name "*.d" -exec mv {} /usr/local/bin/ \; \
    && cd / && rm -rf /tmp/caut) \
    || echo "caut: build skipped"

# Clean Rust build caches
RUN rm -rf /opt/cargo/registry /opt/cargo/git /tmp/*

# ============================================================
# Phase 9: Dicklesworthstone Stack — Script/TS/Python tools
# ============================================================
RUN mkdir -p /opt/acfs

# MCP Agent Mail — inter-agent messaging (Python/FastMCP)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/mcp-agent-mail.git /opt/acfs/mcp-agent-mail \
    && cd /opt/acfs/mcp-agent-mail \
    && (uv venv .venv && uv pip install -e . 2>/dev/null || pip3 install -e . 2>/dev/null || true) \
    && ln -sf /opt/acfs/mcp-agent-mail/.venv/bin/am /usr/local/bin/am 2>/dev/null) \
    || echo "mcp-agent-mail: install skipped"

# Automated Plan Reviser — spec refinement (Bash)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/automated_plan_reviser.git /opt/acfs/apr \
    && chmod +x /opt/acfs/apr/apr 2>/dev/null \
    && ln -sf /opt/acfs/apr/apr /usr/local/bin/apr 2>/dev/null) \
    || echo "apr: install skipped"

# Jeffrey's Prompts — curated agent prompt library (TS/Bun)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/jeffreysprompts.git /opt/acfs/jfp \
    && cd /opt/acfs/jfp && bun install 2>/dev/null \
    && ln -sf /opt/acfs/jfp/bin/jfp /usr/local/bin/jfp 2>/dev/null) \
    || echo "jeffreysprompts: install skipped"

# Ultimate Bug Scanner — AST-aware scanning (Bash, needs ast-grep)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/ultimate_bug_scanner.git /opt/acfs/ubs \
    && chmod +x /opt/acfs/ubs/ubs 2>/dev/null \
    && ln -sf /opt/acfs/ubs/ubs /usr/local/bin/ubs 2>/dev/null) \
    || echo "ubs: install skipped"

# CM — procedural memory for agents (TS/Bun)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/cm.git /opt/acfs/cm \
    && cd /opt/acfs/cm && bun install 2>/dev/null \
    && ln -sf /opt/acfs/cm/bin/cm /usr/local/bin/cm 2>/dev/null) \
    || echo "cm: install skipped"

# Repo Updater — multi-repo sync + AI commits (Bash)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/repo_updater.git /opt/acfs/ru \
    && chmod +x /opt/acfs/ru/ru 2>/dev/null \
    && ln -sf /opt/acfs/ru/ru /usr/local/bin/ru 2>/dev/null) \
    || echo "ru: install skipped"

# Brenner Bot — research session manager (TS/Bun)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/brenner_bot.git /opt/acfs/brenner \
    && cd /opt/acfs/brenner && bun install 2>/dev/null \
    && ln -sf /opt/acfs/brenner/bin/brenner /usr/local/bin/brenner 2>/dev/null) \
    || echo "brenner: install skipped"

# GIIL — download images from URLs (Bash)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/giil.git /opt/acfs/giil \
    && chmod +x /opt/acfs/giil/giil 2>/dev/null \
    && ln -sf /opt/acfs/giil/giil /usr/local/bin/giil 2>/dev/null) \
    || echo "giil: install skipped"

# CSCTF — chat shared conversation to file (Bash)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/csctf.git /opt/acfs/csctf \
    && chmod +x /opt/acfs/csctf/csctf 2>/dev/null \
    && ln -sf /opt/acfs/csctf/csctf /usr/local/bin/csctf 2>/dev/null) \
    || echo "csctf: install skipped"

# S2P — source to prompt TUI (TS/Bun)
RUN (git clone --depth 1 https://github.com/Dicklesworthstone/source_to_prompt_tui.git /opt/acfs/s2p \
    && cd /opt/acfs/s2p && bun install 2>/dev/null \
    && ln -sf /opt/acfs/s2p/bin/s2p /usr/local/bin/s2p 2>/dev/null) \
    || echo "s2p: install skipped"

# Clean Go caches
RUN rm -rf /opt/gopath/pkg /tmp/*

# ============================================================
# Phase 10: ttyd (web terminal) — prebuilt binary
# ============================================================
RUN curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64" -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# ============================================================
# Phase 11: Create default non-root user
# ============================================================
RUN useradd -m -s /bin/zsh -G sudo dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev \
    && mkdir -p /data/projects \
    && chown dev:dev /data/projects

# Install Oh My Zsh + plugins for the default user
RUN su - dev -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' \
    && git clone --depth 1 https://github.com/romkatv/powerlevel10k.git /home/dev/.oh-my-zsh/custom/themes/powerlevel10k \
    && git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /home/dev/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting /home/dev/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && chown -R dev:dev /home/dev/.oh-my-zsh

COPY <<'ZSHRC' /home/dev/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf)
source $ZSH/oh-my-zsh.sh
export PATH="/usr/local/bin:/opt/bun/bin:/opt/cargo/bin:/usr/local/go/bin:$HOME/.local/bin:$PATH"
export RUSTUP_HOME="/opt/rustup"
export CARGO_HOME="/opt/cargo"
export EDITOR=vim
alias ll="eza -la --icons --group-directories-first"
alias la="eza -la --icons"
alias lt="eza --tree --level=2 --icons"
alias cat="bat --paging=never"
alias lg="lazygit"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh 2>/dev/null)" || true
echo "🚀 ACFS Railway — Agentic Coding Flywheel (comprehensive edition)"
echo "   claude | codex | gemini | opencode + 40 tools"
echo ""
ZSHRC
RUN chown dev:dev /home/dev/.zshrc

# Save skeleton home so we can seed the volume on first boot
RUN cp -a /home/dev /etc/skel-dev

# ============================================================
# Entrypoint: set up user/hostname from env vars, then start ttyd
# ============================================================
COPY <<'ENTRYPOINT' /usr/local/bin/entrypoint.sh
#!/bin/bash
set -e

TARGET_USER="${ACFS_USER:-dev}"
TARGET_HOSTNAME="${ACFS_HOSTNAME:-acfs}"

# Rename hostname
echo "$TARGET_HOSTNAME" > /etc/hostname
hostname "$TARGET_HOSTNAME" 2>/dev/null || true

# If user wants a different username than "dev", rename it
if [ "$TARGET_USER" != "dev" ] && id dev &>/dev/null; then
    usermod -l "$TARGET_USER" -d "/home/$TARGET_USER" -m dev 2>/dev/null || true
    groupmod -n "$TARGET_USER" dev 2>/dev/null || true
    sed -i "s/^dev /$TARGET_USER /" /etc/sudoers.d/dev 2>/dev/null || true
fi

TARGET_HOME="/home/$TARGET_USER"

# Seed home directory from skeleton if volume is empty (first boot)
if [ ! -f "$TARGET_HOME/.zshrc" ]; then
    echo "First boot: seeding home directory from skeleton..."
    cp -a /etc/skel-dev/. "$TARGET_HOME/" 2>/dev/null || true
fi

# SSH key setup (from env vars)
SSH_DIR="$TARGET_HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ -n "${SSH_PRIVATE_KEY:-}" ]; then
    echo "$SSH_PRIVATE_KEY" > "$SSH_DIR/id_ed25519"
    chmod 600 "$SSH_DIR/id_ed25519"
    echo "SSH private key installed."
fi

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    echo "$SSH_PUBLIC_KEY" > "$SSH_DIR/id_ed25519.pub"
    chmod 644 "$SSH_DIR/id_ed25519.pub"
    echo "SSH public key installed."
fi

# Default SSH config (persists in volume, only written on first boot)
if [ ! -f "$SSH_DIR/config" ]; then
    cat > "$SSH_DIR/config" <<'SSHCFG'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new

Host *
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
SSHCFG
    chmod 600 "$SSH_DIR/config"
fi

# Git config from env vars
if [ -n "${GIT_USER_NAME:-}" ]; then
    su - "$TARGET_USER" -c "git config --global user.name '${GIT_USER_NAME}'"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
    su - "$TARGET_USER" -c "git config --global user.email '${GIT_USER_EMAIL}'"
fi

# Ensure ownership
chown -R "$TARGET_USER:$(id -gn "$TARGET_USER")" "$TARGET_HOME" 2>/dev/null || true
chown "$TARGET_USER:$(id -gn "$TARGET_USER")" /data/projects 2>/dev/null || true

# Start ttyd as the target user
exec ttyd -W -p "${PORT:-7681}" \
    -c "${TTYD_USER:-admin}:${TTYD_PASS:-changeme}" \
    -t titleFixed="${TARGET_HOSTNAME} terminal" \
    su - "$TARGET_USER"
ENTRYPOINT
RUN chmod +x /usr/local/bin/entrypoint.sh

# Final cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /data/projects
EXPOSE 7681

CMD ["/usr/local/bin/entrypoint.sh"]
