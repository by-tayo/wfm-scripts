#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting package installation...${NC}"

# Detect package manager using /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION_ID=$VERSION_ID
else
    echo -e "${RED}Cannot detect distro${NC}"
    exit 1
fi

case $DISTRO in
    ubuntu|debian)
        PKG_MGR="apt"
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
        ;;
    fedora)
        PKG_MGR="dnf"
        PKG_UPDATE="dnf check-update"
        PKG_INSTALL="dnf install -y"
        ;;
    rhel|centos)
        if [[ $VERSION_ID == "8"* || $VERSION_ID == "9"* ]]; then
            PKG_MGR="dnf"
        else
            PKG_MGR="yum"
        fi
        PKG_UPDATE="$PKG_MGR check-update"
        PKG_INSTALL="$PKG_MGR install -y"
        ;;
    *)
        echo -e "${RED}Unsupported distro: $DISTRO${NC}"
        exit 1
        ;;
esac

echo "Detected: $DISTRO with $PKG_MGR"

# Update system
$PKG_UPDATE
$PKG_INSTALL curl ca-certificates gnupg lsb-release

# Install Git
$PKG_INSTALL git
echo -e "${GREEN}Git installed${NC}"

# Install Node.js (LTS)
if [ "$PKG_MGR" = "apt" ]; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
elif [ "$PKG_MGR" = "dnf" ] || [ "$PKG_MGR" = "yum" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
fi
$PKG_INSTALL nodejs
echo -e "${GREEN}Node.js installed (v$(node --version))${NC}"

# Install Docker
if [ "$PKG_MGR" = "apt" ]; then
    # Docker apt repo setup
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    $PKG_UPDATE
    $PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker $USER || true
elif [[ "$PKG_MGR" = "dnf" || "$PKG_MGR" = "yum" ]]; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER || true
fi
systemctl enable --now docker || true
echo -e "${GREEN}Docker installed${NC}"

# Installing Ansible, Terraform, JQ, tmux, and htop
echo -e "${GREEN}Installing core DevOps tools...${NC}"
$PKG_INSTALL ansible terraform jq tmux htop
echo -e "${GREEN}Ansible, Terraform, jq, tmux, htop installed${NC}"

# Installing Kubernetes CLI
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo -e "${GREEN}kubectl installed${NC}"

# Installing Prometheus and Grafana
if [ "$PKG_MGR" = "apt" ]; then
    $PKG_INSTALL software-properties-common
    curl -fsSL https://packages.grafana.com/gpg.key | gpg --dearmor -o /usr/share/keyrings/grafana-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/grafana-archive-keyring.gpg] https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
    $PKG_UPDATE
    $PKG_INSTALL prometheus prometheus-node-exporter grafana
    systemctl enable --now prometheus grafana-server || true
fi

echo -e "${GREEN}All packages installed!${NC}"
