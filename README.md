# Workflow Management Scripts

A collection of scripts for day-to-day workflow management, environment setup, system
administration, network diagnostics, and DevOps tasks — organized by category under
`wfm-scripts/`.

Scripts that delete or modify things are called out below. Several default to a **dry run**
(report only, nothing changed) and require an explicit `--execute` flag to actually act —
read a script before running it with elevated privileges or against a system you care about.

## file-management/

Windows duplicate-file detection, for cleaning up `(1)`, `(2)`-style copies in common user
folders.

| Script | Description |
|---|---|
| `documents_checks_script.ps1` | Scans `Documents` for duplicate copies, prompts per file before deleting. |
| `documents_checks_bulk.ps1` | Same scan, single prompt to delete all detected duplicates at once. |
| `downloads_checks_script.ps1` | Scans `Downloads` for duplicate copies, prompts per file before deleting. |
| `downloads_checks_bulk.ps1` | Same scan, single prompt to delete all detected duplicates at once. |

## environment-setup/

Provisioning scripts for a fresh dev machine.

| Script | Description |
|---|---|
| `setup-linux.sh` | Linux/WSL2 terminal + dev environment: zsh, Oh My Zsh, tmux, fzf, eza, bat, btop, Docker, Neovim. Safe to re-run. |
| `setup-windows.ps1` | Windows dev environment via Chocolatey: Git, VS Code, WSL2, Docker Desktop, Windows Terminal, recon/pentest tooling. Run as Administrator. |
| `automate-package-installation.sh` | Detects the Linux distro/package manager and installs a core DevOps toolchain: Git, Node.js, Docker, Ansible, Terraform, kubectl, Prometheus + Grafana. |

## sysadmin/

| Script | Description |
|---|---|
| `data-backup-script.sh` | Tars up `/home`, `/etc`, `/var/www` to a backup destination. |
| `setup-ssh-hardening.sh` | Hardens `sshd_config` (key-only auth, disables root login, etc.), sets up Fail2ban + ufw + Netbird. **For a lab VM/server you control remotely — never your main machine.** Has `--dry-run`. |
| `disk-usage-report.sh` | Read-only: filesystem summary, top-N largest directories and files under a path. |
| `service-health-check.sh` | Read-only: reports failed systemd units, plus status of any specific services you list. |
| `log-cleanup.sh` | Deletes log files older than N days under a path. **Defaults to a dry run** — pass `--execute` to actually delete. |

## network-engineering/

All read-only diagnostics — no configuration changes.

| Script | Description |
|---|---|
| `port-connectivity-check.sh` | Tests TCP reachability of a host on a list of ports (or common defaults), reports open/closed/filtered. |
| `dns-lookup-report.sh` | Resolves a domain against several public resolvers (Google, Cloudflare, Quad9) side by side — useful for spotting propagation lag. |
| `network-interface-report.sh` | Dumps interfaces/IPs, routing table, DNS servers, and listening ports in one report. |

## devops/

| Script | Description |
|---|---|
| `docker-cleanup.sh` | Reports stopped containers, dangling images, unused networks/volumes. **Defaults to a dry run** — pass `--execute` to actually prune. |
| `git-repo-health-check.sh` | Read-only: scans a directory tree for git repos, flags uncommitted changes, missing upstreams, and ahead/behind status. |
| `k8s-namespace-report.sh` | Read-only: pod/deployment/PVC status for a namespace, flags non-Running or high-restart pods, tails recent warning events. |
