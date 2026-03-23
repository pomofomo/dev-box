# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Infrastructure-as-code for provisioning and configuring a dev box on Hetzner Cloud. Terraform creates the server, Ansible configures it.

## Commands

```bash
# Terraform
terraform init                  # Initialize providers
terraform apply                 # Provision server
terraform output server_ip      # Get server IP
terraform destroy               # Tear down server

# Ansible (from ansible/ directory)
ansible-playbook -i inventory.ini playbook.yml       # Base setup
ansible-playbook -i inventory.ini post-setup.yml      # After manual steps (Netbird, etc.)
ansible-playbook -i inventory.ini post-setup.yml --extra-vars "telegram_bot_token=TOKEN"

# Ansible Galaxy (local prerequisite)
ansible-galaxy collection install community.docker
```

## Architecture

Two-phase deployment:

1. **`playbook.yml`** — runs first, installs everything that doesn't need interactive auth: system packages, Docker, firewall, Netbird, Rust, Go, NVM, Bun, GitHub CLI, Claude Code, language servers, bashrc/PATH setup.

2. **Manual steps** — user SSHs in and does: `netbird up`, `claude` (login), `gh auth login`, adds SSH key to GitHub, optionally creates Telegram bot.

3. **`post-setup.yml`** — runs after manual steps. Installs Portainer (bound to Netbird IP:9999, needs Netbird connected) and writes Telegram bot token.

## Key conventions

- Ansible connects as root but creates a `dev` user. System tasks (apt, firewall, docker install) run as root. User tasks (rustup, nvm, claude, etc.) use `become_user: "{{ dev_user }}"`.
- All ansible task files use `dev_user` and `dev_home` variables — never hardcode paths or use `ansible_env`.
- Portainer and Telegram channel are in `post-setup.yml` because they depend on manual auth steps completing first.
- Go is installed via snap (not tarball), so PATH uses `/snap/bin`.
- Firewall: default deny incoming, allow SSH on public, allow all on Netbird interface (`wt0`).
- The `community.docker` Ansible collection is required for `post-setup.yml` (portainer task).
- `terraform.tfvars` and `ansible/inventory.ini` are gitignored — only `.example` templates are committed.

## Server spec

Hetzner CPX42 (default, configurable via `server_type` variable): 8 vCPU, 16 GB RAM, Ubuntu 24.04.
