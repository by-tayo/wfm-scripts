#!/usr/bin/env bash
#
# Optional lab-VM hardening script: SSH key-only auth, Fail2ban, Netbird.
#
# This is SEPARATE from setup-linux.sh on purpose — only run this on a
# VM/server you actually control remotely (lab box, VPS), never on your
# main dev machine, since it disables password SSH login.
#
# Usage:
#   chmod +x setup-ssh-hardening.sh
#   sudo ./setup-ssh-hardening.sh --user yourusername
#
# Flags:
#   --user <name>       Username to allow via AllowUsers (required)
#   --port <port>       SSH port to use (default: 22, change if desired)
#   --skip-netbird       Skip Netbird install/setup
#   --skip-fail2ban      Skip Fail2ban install/setup
#   --dry-run            Print what would happen, don't modify anything

set -euo pipefail

SSH_USER=""
SSH_PORT="22"
SKIP_NETBIRD=false
SKIP_FAIL2BAN=false
DRY_RUN=false

while [ $# -gt 0 ]; do
    case "$1" in
        --user) SSH_USER="$2"; shift 2 ;;
        --port) SSH_PORT="$2"; shift 2 ;;
        --skip-netbird) SKIP_NETBIRD=true; shift ;;
        --skip-fail2ban) SKIP_FAIL2BAN=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
done

section() {
    echo ""
    echo "=== $1 ==="
}

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (sudo ./setup-ssh-hardening.sh --user <name>)."
    exit 1
fi

if [ -z "$SSH_USER" ]; then
    echo "You must specify --user <name> — the account that will be allowed to SSH in."
    echo "Example: sudo ./setup-ssh-hardening.sh --user cry0l1t3"
    exit 1
fi

echo "⚠️  This will disable SSH password authentication and restrict logins to: $SSH_USER"
echo "    Make sure that user already has a public key in ~/.ssh/authorized_keys"
echo "    before you continue, or you will lock yourself out."
if [ "$DRY_RUN" = false ]; then
    read -p "Type 'yes' to continue: " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

run() {
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] $*"
    else
        eval "$@"
    fi
}

section "Updating system"
run "apt update -y && apt full-upgrade -y && apt autoremove -y && apt autoclean -y"

# ---------------------------------------------------------------------------
if [ "$SKIP_FAIL2BAN" = false ]; then
    section "Fail2ban"
    run "apt install -y fail2ban"
    if [ ! -f /etc/fail2ban/jail.local ]; then
        run "cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local"
    fi
    if [ "$DRY_RUN" = false ]; then
        if ! grep -q "^\[sshd\]" /etc/fail2ban/jail.local; then
            cat >> /etc/fail2ban/jail.local << EOF

[sshd]
enabled = true
bantime = 4w
maxretry = 3
port = $SSH_PORT
EOF
        fi
        systemctl restart fail2ban
        systemctl enable fail2ban
    fi
else
    echo "Skipping Fail2ban (per --skip-fail2ban flag)."
fi

# ---------------------------------------------------------------------------
section "Backing up sshd_config"
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak_$(date +%F_%H-%M-%S)"
run "cp $SSHD_CONFIG $BACKUP_CONFIG"
echo "Backup saved to $BACKUP_CONFIG"

section "Hardening sshd_config"
if [ "$DRY_RUN" = false ]; then
    apply_setting() {
        local key="$1"
        local value="$2"
        if grep -qE "^\s*#?\s*${key}\b" "$SSHD_CONFIG"; then
            sed -i "s|^\s*#\?\s*${key}\s.*|${key} ${value}|" "$SSHD_CONFIG"
        else
            echo "${key} ${value}" >> "$SSHD_CONFIG"
        fi
    }

    apply_setting "LogLevel" "VERBOSE"
    apply_setting "PermitRootLogin" "no"
    apply_setting "MaxAuthTries" "3"
    apply_setting "MaxSessions" "5"
    apply_setting "HostbasedAuthentication" "no"
    apply_setting "PermitEmptyPasswords" "no"
    apply_setting "UsePAM" "yes"
    apply_setting "X11Forwarding" "no"
    apply_setting "PrintMotd" "no"
    apply_setting "ClientAliveInterval" "600"
    apply_setting "ClientAliveCountMax" "0"
    apply_setting "AllowUsers" "$SSH_USER"
    apply_setting "Protocol" "2"
    apply_setting "PasswordAuthentication" "no"
    apply_setting "Port" "$SSH_PORT"

    echo "Validating sshd config..."
    if sshd -t; then
        echo "Config valid."
    else
        echo "Config INVALID — restoring backup and aborting."
        cp "$BACKUP_CONFIG" "$SSHD_CONFIG"
        exit 1
    fi

    systemctl restart sshd
    echo "SSH service restarted with hardened config on port $SSH_PORT."
else
    echo "[dry-run] Would apply hardened sshd_config settings and restart sshd."
fi

# ---------------------------------------------------------------------------
section "Firewall (ufw)"
if [ "$DRY_RUN" = false ]; then
    apt install -y ufw
    ufw allow "$SSH_PORT"/tcp
    ufw default deny incoming
    ufw default allow outgoing
    ufw --force enable
    ufw status
else
    echo "[dry-run] Would configure ufw to allow port $SSH_PORT and deny other incoming traffic."
fi

# ---------------------------------------------------------------------------
if [ "$SKIP_NETBIRD" = false ]; then
    section "Netbird"
    if command -v netbird >/dev/null 2>&1; then
        echo "Netbird already installed."
    else
        if [ "$DRY_RUN" = false ]; then
            curl -fsSL https://pkgs.netbird.io/install.sh | sh
            echo ""
            echo "Netbird installed. Run this manually with your setup key:"
            echo "    netbird up --setup-key <YOUR-SETUP-KEY>"
            echo "Then approve the peer in your Netbird dashboard."
        else
            echo "[dry-run] Would install Netbird via https://pkgs.netbird.io/install.sh"
        fi
    fi
else
    echo "Skipping Netbird (per --skip-netbird flag)."
fi

section "Done"
echo "SSH hardening complete."
echo ""
echo "IMPORTANT — before closing this session:"
echo "  1. Open a NEW terminal and confirm you can still SSH in as $SSH_USER on port $SSH_PORT"
echo "  2. Only close this current session after that new connection succeeds"
echo "  3. If using Netbird, run 'netbird up --setup-key <key>' and approve the peer,"
echo "     then consider restricting sshd/ufw to only the Netbird (wt0) interface"
