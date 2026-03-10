# ============================================================
# ACFS Railway Template — Agentic Coding Flywheel on Railway
# A containerized multi-agent AI development environment
# ============================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    NEEDRESTART_MODE=a \
    NEEDRESTART_SUSPEND=1 \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    TERM=xterm-256color \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/zsh

# ============================================================
# Phase 1: Base system + modern CLI tools
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates unzip tar xz-utils jq build-essential \
    gnupg lsb-release wget sudo zsh locales procps htop vim nano \
    cmake libwebsockets-dev libssl-dev pkg-config libsqlite3-dev \
    python3 python3-pip python3-venv \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================================
# Phase 2: Modern CLI replacements
# ============================================================

# bat (cat replacement)
RUN curl -fsSL "https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/bat-v0.24.0-x86_64-unknown-linux-gnu/bat /usr/local/bin/ && rm -rf /tmp/bat-*

# fd (find replacement)
RUN curl -fsSL "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/fd-v10.2.0-x86_64-unknown-linux-gnu/fd /usr/local/bin/ && rm -rf /tmp/fd-*

# ripgrep (grep replacement)
RUN curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/ripgrep-14.1.1-x86_64-unknown-linux-musl/rg /usr/local/bin/ && rm -rf /tmp/ripgrep-*

# eza (ls replacement)
RUN curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/eza /usr/local/bin/ && rm -rf /tmp/eza*

# delta (diff replacement)
RUN curl -fsSL "https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp && mv /tmp/delta-0.18.2-x86_64-unknown-linux-gnu/delta /usr/local/bin/ && rm -rf /tmp/delta-*

# fzf (fuzzy finder)
RUN curl -fsSL "https://github.com/junegunn/fzf/releases/download/v0.57.0/fzf-0.57.0-linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin/

# zoxide (smart cd)
RUN curl -fsSL "https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.6/zoxide-0.9.6-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/local/bin/ zoxide

# lazygit
RUN curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v0.44.1/lazygit_0.44.1_Linux_x86_64.tar.gz" \
    | tar -xz -C /usr/local/bin/ lazygit

# ============================================================
# Phase 3: Language runtimes
# ============================================================

# Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/root/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"

# uv (Python)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:$PATH"

# Go
RUN curl -fsSL "https://go.dev/dl/go1.23.6.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:/root/go/bin:$PATH"

# Node.js LTS (via n)
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o /usr/local/bin/n \
    && chmod +x /usr/local/bin/n \
    && n lts

# ============================================================
# Phase 4: AI Coding Agents
# ============================================================

# Claude Code (via npm)
RUN npm install -g @anthropic-ai/claude-code

# Codex CLI (OpenAI — via npm)
RUN npm install -g @openai/codex 2>/dev/null || echo "codex: will install at runtime if available"

# Gemini CLI (Google — via npm)
RUN npm install -g @anthropic-ai/claude-code @google/gemini-cli 2>/dev/null || echo "gemini: will install at runtime if available"

# ============================================================
# Phase 5: Dicklesworthstone Stack (Rust tools)
# ============================================================

# NTM (Neural Task Manager)
RUN git clone --depth 1 https://github.com/Dicklesworthstone/ntm.git /tmp/ntm \
    && cd /tmp/ntm && cargo build --release \
    && mv target/release/ntm /usr/local/bin/ \
    && cd / && rm -rf /tmp/ntm

# SLB (Super Linter/Bug finder)
RUN git clone --depth 1 https://github.com/Dicklesworthstone/slb.git /tmp/slb \
    && cd /tmp/slb && cargo build --release \
    && mv target/release/slb /usr/local/bin/ \
    && cd / && rm -rf /tmp/slb

# Beads
RUN git clone --depth 1 https://github.com/Dicklesworthstone/beads.git /tmp/beads \
    && cd /tmp/beads && cargo build --release \
    && mv target/release/beads /usr/local/bin/ \
    && cd / && rm -rf /tmp/beads

# CM (Context Manager)
RUN git clone --depth 1 https://github.com/Dicklesworthstone/cm.git /tmp/cm \
    && cd /tmp/cm && cargo build --release \
    && mv target/release/cm /usr/local/bin/ \
    && cd / && rm -rf /tmp/cm

# CASS
RUN git clone --depth 1 https://github.com/Dicklesworthstone/cass.git /tmp/cass \
    && cd /tmp/cass && cargo build --release \
    && mv target/release/cass /usr/local/bin/ \
    && cd / && rm -rf /tmp/cass

# Clean up cargo/rustup caches from builds
RUN rm -rf /root/.cargo/registry /root/.cargo/git /tmp/*

# ============================================================
# Phase 6: Oh My Zsh + Powerlevel10k
# ============================================================
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth 1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k \
    && git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

COPY <<'ZSHRC' /root/.zshrc
export ZSH="/root/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf)
source $ZSH/oh-my-zsh.sh

# PATH
export PATH="/root/.local/bin:/root/.bun/bin:/root/.cargo/bin:/usr/local/go/bin:/root/go/bin:$PATH"

# Aliases (modern replacements)
alias ll="eza -la --icons --group-directories-first"
alias la="eza -la --icons"
alias lt="eza --tree --level=2 --icons"
alias cat="bat --paging=never"
alias lg="lazygit"

# zoxide
eval "$(zoxide init zsh)"

# Welcome
echo "🚀 ACFS Railway — Agentic Coding Flywheel"
echo "   claude, codex, gemini — ready to code"
echo ""
ZSHRC

# ============================================================
# Phase 7: ttyd (web terminal)
# ============================================================
RUN git clone --depth 1 https://github.com/tsl0922/ttyd.git /tmp/ttyd \
    && cd /tmp/ttyd && mkdir build && cd build \
    && cmake .. && make -j$(nproc) && make install \
    && cd / && rm -rf /tmp/ttyd

# Workspace
RUN mkdir -p /data/projects
WORKDIR /data/projects

# Default shell
RUN chsh -s /bin/zsh root

EXPOSE 7681

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -fsS http://localhost:${PORT:-7681}/ || exit 1

CMD ["sh", "-c", "ttyd -p ${PORT:-7681} -t titleFixed='ACFS Terminal' -c ${TTYD_USER:-admin}:${TTYD_PASS:-changeme} /bin/zsh"]
