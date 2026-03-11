# ============================================================
# ACFS Railway — Agentic Coding Flywheel on Railway
# Browser-accessible coding terminal with AI agents pre-installed
# ============================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    NEEDRESTART_MODE=a \
    TERM=xterm-256color \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/zsh

# Configurable user and hostname (override via Railway env vars)
ENV ACFS_USER=coder \
    ACFS_HOSTNAME=acfs

# ============================================================
# Phase 1: Base system packages
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates unzip tar xz-utils jq build-essential \
    gnupg wget sudo zsh locales procps htop vim nano tmux \
    libssl-dev pkg-config \
    python3 python3-pip python3-venv \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================================
# Phase 2: Go (needed for Dicklesworthstone stack)
# ============================================================
RUN curl -fsSL "https://go.dev/dl/go1.23.6.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:$PATH"

# ============================================================
# Phase 3: Modern CLI tools (installed globally)
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

# ============================================================
# Phase 4: Language runtimes (install globally, then copy to user)
# ============================================================

# Bun (global install)
ENV BUN_INSTALL="/opt/bun"
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="$BUN_INSTALL/bin:$PATH"

# uv (Python)
RUN curl -LsSf https://astral.sh/uv/install.sh | CARGO_HOME=/opt/uv sh
RUN mv /root/.local/bin/uv /usr/local/bin/ 2>/dev/null || mv /opt/uv/bin/uv /usr/local/bin/ 2>/dev/null || true
RUN mv /root/.local/bin/uvx /usr/local/bin/ 2>/dev/null || true

# Rust (install to shared location)
ENV RUSTUP_HOME="/opt/rustup" \
    CARGO_HOME="/opt/cargo"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/opt/cargo/bin:$PATH"

# Node.js LTS (via n — installs to /usr/local)
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o /usr/local/bin/n \
    && chmod +x /usr/local/bin/n \
    && n lts

# ============================================================
# Phase 5: AI Coding Agents (global npm)
# ============================================================
RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g @openai/codex 2>/dev/null || echo "codex: not yet available via npm"
RUN npm install -g @google/gemini-cli 2>/dev/null || echo "gemini: not yet available via npm"

# ============================================================
# Phase 6: Dicklesworthstone Stack (Go tools)
# ============================================================
ENV GOPATH="/opt/gopath"
RUN go install github.com/Dicklesworthstone/ntm@latest 2>/dev/null || \
    (git clone --depth 1 https://github.com/Dicklesworthstone/ntm.git /tmp/ntm \
    && cd /tmp/ntm && go build -o /usr/local/bin/ntm . && cd / && rm -rf /tmp/ntm) \
    || echo "ntm: build skipped"
RUN cp /opt/gopath/bin/* /usr/local/bin/ 2>/dev/null || true

RUN go install github.com/Dicklesworthstone/simultaneous_launch_button@latest 2>/dev/null || \
    (git clone --depth 1 https://github.com/Dicklesworthstone/simultaneous_launch_button.git /tmp/slb \
    && cd /tmp/slb && go build -o /usr/local/bin/slb . && cd / && rm -rf /tmp/slb) \
    || echo "slb: build skipped"
RUN cp /opt/gopath/bin/* /usr/local/bin/ 2>/dev/null || true

# Beads (Rust — issue tracker)
RUN git clone --depth 1 https://github.com/Dicklesworthstone/beads_rust.git /tmp/beads \
    && cd /tmp/beads && cargo build --release \
    && mv target/release/beads* /usr/local/bin/ 2>/dev/null \
    && cd / && rm -rf /tmp/beads \
    || echo "beads: build skipped"

# Clean build caches
RUN rm -rf /opt/cargo/registry /opt/cargo/git /opt/gopath/pkg /tmp/*

# ============================================================
# Phase 7: ttyd (web terminal) — prebuilt binary
# ============================================================
RUN curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64" -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# ============================================================
# Phase 8: Create default non-root user
# We create a "coder" user at build time. The entrypoint
# script handles renaming user/hostname from env vars at runtime.
# ============================================================
RUN useradd -m -s /bin/zsh -G sudo coder \
    && echo 'coder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder \
    && mkdir -p /data/projects \
    && chown coder:coder /data/projects

# Install Oh My Zsh + plugins for the default user
RUN su - coder -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' \
    && git clone --depth 1 https://github.com/romkatv/powerlevel10k.git /home/coder/.oh-my-zsh/custom/themes/powerlevel10k \
    && git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /home/coder/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting /home/coder/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && chown -R coder:coder /home/coder/.oh-my-zsh

COPY <<'ZSHRC' /home/coder/.zshrc
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
echo "🚀 ACFS Railway — Agentic Coding Flywheel"
echo "   claude | codex | gemini — ready to code"
echo ""
ZSHRC
RUN chown coder:coder /home/coder/.zshrc

# ============================================================
# Entrypoint: set up user/hostname from env vars, then start ttyd
# ============================================================
COPY <<'ENTRYPOINT' /usr/local/bin/entrypoint.sh
#!/bin/bash
set -e

TARGET_USER="${ACFS_USER:-coder}"
TARGET_HOSTNAME="${ACFS_HOSTNAME:-acfs}"

# Rename hostname
echo "$TARGET_HOSTNAME" > /etc/hostname
hostname "$TARGET_HOSTNAME" 2>/dev/null || true

# If user wants a different username than "coder", rename it
if [ "$TARGET_USER" != "coder" ] && id coder &>/dev/null; then
    usermod -l "$TARGET_USER" -d "/home/$TARGET_USER" -m coder 2>/dev/null || true
    groupmod -n "$TARGET_USER" coder 2>/dev/null || true
    sed -i "s/^coder /$TARGET_USER /" /etc/sudoers.d/coder 2>/dev/null || true
fi

TARGET_HOME=$(eval echo "~$TARGET_USER")

# Ensure workspace ownership
chown "$TARGET_USER:$TARGET_USER" /data/projects 2>/dev/null || true

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
