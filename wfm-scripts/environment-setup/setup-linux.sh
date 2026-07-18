#!/usr/bin/env bash
#
# All-in-one Linux/WSL2 terminal + dev environment setup.
#
# Installs: Zsh + Oh My Zsh + Powerlevel10k + plugins, Tmux (+ TPM),
# FZF, Eza, Bat, Btop, Docker (if not present), Posting (API client),
# Neovim + NvChad (optional).
#
# Safe to re-run — checks for existing installs before doing work.
#
# Usage:
#   chmod +x setup-linux.sh
#   ./setup-linux.sh
#
# Optional flags:
#   --skip-docker      Skip Docker install
#   --skip-neovim       Skip Neovim/NvChad install
#   --no-shell-switch   Don't change default shell to zsh

set -euo pipefail

SKIP_DOCKER=false
SKIP_NEOVIM=false
NO_SHELL_SWITCH=false

for arg in "$@"; do
    case "$arg" in
        --skip-docker) SKIP_DOCKER=true ;;
        --skip-neovim) SKIP_NEOVIM=true ;;
        --no-shell-switch) NO_SHELL_SWITCH=true ;;
    esac
done

section() {
    echo ""
    echo "=== $1 ==="
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

section "Updating package lists"
sudo apt update -y

section "Core packages"
sudo apt install -y git curl wget build-essential unzip

# ---------------------------------------------------------------------------
section "Zsh"
# ---------------------------------------------------------------------------
if command_exists zsh; then
    echo "Zsh already installed, skipping."
else
    sudo apt install -y zsh
fi

section "Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh already installed, skipping."
else
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

section "Zsh plugins (autosuggestions, syntax-highlighting)"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "zsh-autosuggestions already present, skipping."
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting already present, skipping."
fi

# Enable plugins in .zshrc if not already enabled
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
        sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc" 2>/dev/null || true
    fi
fi

section "Powerlevel10k theme"
if [ ! -d "$HOME/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$HOME/.zshrc"
else
    echo "Powerlevel10k already present, skipping."
fi

if [ "$NO_SHELL_SWITCH" = false ]; then
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing default shell to zsh (you may be prompted for your password)..."
        chsh -s "$(which zsh)" || echo "Could not change shell automatically — run 'chsh -s \$(which zsh)' manually."
    fi
fi

# ---------------------------------------------------------------------------
section "Tmux"
# ---------------------------------------------------------------------------
if command_exists tmux; then
    echo "Tmux already installed, skipping."
else
    sudo apt install -y tmux
fi

if [ ! -f "$HOME/.tmux.conf" ]; then
    cat > "$HOME/.tmux.conf" << 'EOF'
# Config Management
unbind r
bind r source-file ~/.tmux.conf \; display "Config reloaded."

# Control
set -g prefix C-space
set -g mouse on

# History
set-option -g history-limit 50000

# Numbering
set -g base-index 1
setw -g pane-base-index 1

# Panes
bind x split-window -v
bind y split-window -h
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
run '~/.tmux/plugins/tpm/tpm'
EOF
    echo "Wrote default ~/.tmux.conf"
else
    echo "~/.tmux.conf already exists, leaving it untouched."
fi

section "Tmux Plugin Manager (TPM)"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    # Install plugins headlessly
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || echo "Run tmux, then Ctrl+Space Shift+I to install plugins interactively."
else
    echo "TPM already present, skipping."
fi

# ---------------------------------------------------------------------------
section "FZF"
# ---------------------------------------------------------------------------
if [ -d "$HOME/.fzf" ]; then
    echo "FZF already installed, skipping."
else
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
    if [ -f "$HOME/.fzf.zsh" ] && ! grep -q ".fzf.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' >> "$HOME/.zshrc"
    fi
fi

# ---------------------------------------------------------------------------
section "Eza (modern ls)"
# ---------------------------------------------------------------------------
if command_exists eza; then
    echo "Eza already installed, skipping."
else
    sudo apt install -y eza || {
        echo "eza not available via apt on this distro — installing via cargo/binary fallback skipped. Install manually if needed."
    }
fi

# ---------------------------------------------------------------------------
section "Bat (cat with syntax highlighting)"
# ---------------------------------------------------------------------------
if command_exists bat || command_exists batcat; then
    echo "Bat already installed, skipping."
else
    sudo apt install -y bat
fi

# ---------------------------------------------------------------------------
section "Btop (system monitor)"
# ---------------------------------------------------------------------------
if command_exists btop; then
    echo "Btop already installed, skipping."
else
    sudo apt install -y btop
fi

# ---------------------------------------------------------------------------
section "Aliases (added to ~/.zshrc if not already present)"
# ---------------------------------------------------------------------------
ALIAS_BLOCK='
# --- env-setup-scripts aliases ---
alias ff="fzf --style full --preview '"'"'([ -d {} ] && eza --tree --level=2 {} || bat --color=always {}) 2>/dev/null'"'"'"
alias ls="eza"
alias l="eza --git-ignore"
alias ll="eza --all --header --long"
alias llm="eza --all --header --long --sort=modified"
alias la="eza -lbhHigUmuSa"
alias lt="eza --tree"
alias tree="eza --tree"
# --- end env-setup-scripts aliases ---
'

if [ -f "$HOME/.zshrc" ] && ! grep -q "env-setup-scripts aliases" "$HOME/.zshrc"; then
    echo "$ALIAS_BLOCK" >> "$HOME/.zshrc"
    echo "Added aliases to ~/.zshrc"
else
    echo "Aliases already present or .zshrc missing, skipping."
fi

# ---------------------------------------------------------------------------
if [ "$SKIP_DOCKER" = false ]; then
    section "Docker"
    if command_exists docker; then
        echo "Docker already installed, skipping."
    else
        sudo apt install -y docker.io
        sudo usermod -aG docker "$USER"
        echo "Docker installed. You'll need to log out/in (or run 'newgrp docker') for group changes to apply."
    fi
else
    echo "Skipping Docker (per --skip-docker flag)."
fi

# ---------------------------------------------------------------------------
if [ "$SKIP_NEOVIM" = false ]; then
    section "Neovim + NvChad"
    if command_exists nvim; then
        echo "Neovim already installed, skipping."
    else
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        rm nvim-linux-x86_64.tar.gz
        if ! grep -q "/opt/nvim-linux-x86_64/bin" "$HOME/.zshrc" 2>/dev/null; then
            echo 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"' >> "$HOME/.zshrc"
        fi
    fi

    if [ ! -d "$HOME/.config/nvim" ]; then
        git clone https://github.com/NvChad/starter "$HOME/.config/nvim"
    else
        echo "~/.config/nvim already exists, skipping NvChad clone."
    fi
else
    echo "Skipping Neovim/NvChad (per --skip-neovim flag)."
fi

# ---------------------------------------------------------------------------
section "Posting (terminal API client)"
# ---------------------------------------------------------------------------
if command_exists posting; then
    echo "Posting already installed, skipping."
else
    sudo apt install -y pipx
    pipx ensurepath
    pipx install posting || echo "Posting install failed — try 'pipx install posting' manually after restarting your shell."
fi

# ---------------------------------------------------------------------------
section "Done"
# ---------------------------------------------------------------------------
echo "Core Linux/WSL2 terminal + dev stack installed."
echo ""
echo "Next steps:"
echo "  - Restart your terminal (or run 'exec zsh') to load the new shell config"
echo "  - Run 'p10k configure' the first time you open zsh to set up your prompt"
echo "  - Inside tmux, press Ctrl+Space then Shift+I to finish installing tmux plugins if it wasn't automatic"
echo "  - If Docker was just installed, log out/in or run 'newgrp docker' before using it without sudo"
echo ""
echo "Optional next script: setup-ssh-hardening.sh (for lab VMs — SSH hardening, Fail2ban, Netbird)"
