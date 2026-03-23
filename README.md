# dev box scripts

## Prerequisites

- A Hetzner Cloud account
- [Terraform](https://developer.hashicorp.com/terraform/install) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) installed locally

Quick install on Linux:

```bash
# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Ansible
sudo apt install pipx
pipx install --include-deps ansible
pipx ensurepath

# Ansible Docker module (needed for post-setup.yml)
ansible-galaxy collection install community.docker
```

## Terraform variables

Copy the example file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

| Variable | Required | Description | How to get it |
|----------|----------|-------------|---------------|
| `hcloud_token` | yes | Hetzner Cloud API token | Go to [Hetzner Cloud Console](https://console.hetzner.cloud/) → select a project (or create one) → Security → API Tokens → Generate API Token. Select Read & Write permissions. |
| `ssh_public_key` | yes | Your SSH public key for server access | Run `cat ~/.ssh/id_ed25519.pub` locally. If you don't have one, generate with `ssh-keygen -t ed25519`. |
| `server_name` | no | Name for the server (default: `dev-box`) | Any name you like. |
| `location` | no | Hetzner datacenter (default: `fsn1`) | Options: `fsn1` (Falkenstein), `nbg1` (Nuremberg), `hel1` (Helsinki), `ash` (Ashburn), `hil` (Hillsboro). |

The server type is CPX41 (8 vCPU, 16 GB RAM, Ubuntu 24.04).

## Quick start

### Step 1 — Provision the server

```bash
terraform init
terraform apply
terraform output server_ip
```

### Step 2 — Run the base playbook

```bash
cd ansible
cp inventory.ini.example inventory.ini
# Edit inventory.ini — replace YOUR_SERVER_IP with the IP from step 1
ansible-playbook -i inventory.ini playbook.yml
```

### Step 3 — Complete manual steps

SSH into the server and complete the manual steps listed below.

### Step 4 — Run the post-setup playbook

After completing manual steps (at minimum `netbird up`), run the second playbook to set up services that depend on them:

```bash
# Without Telegram:
ansible-playbook -i inventory.ini post-setup.yml

# With Telegram bot token:
ansible-playbook -i inventory.ini post-setup.yml --extra-vars "telegram_bot_token=YOUR_TOKEN"
```

This installs:
- **Portainer** — Docker management UI, bound to Netbird IP on port 9999
- **Telegram channel** — writes bot token to `~/.claude/channels/telegram/.env`

## What gets installed

### Base playbook (`playbook.yml`)

| Tool | Method |
|------|--------|
| Docker + Compose v2 | apt (official Docker repo) |
| Netbird | apt (official repo) |
| Rust + cargo | rustup |
| Go 1.26 | snap --classic |
| Node.js LTS | nvm |
| Bun | official install script |
| GitHub CLI | apt (official repo) |
| Claude Code | npm global |
| Language servers | typescript, gopls, rust-analyzer, svelte, html/css/json, yaml, bash |
| Claude LSP config | `~/.claude/.lsp.json` wiring up all language servers |
| UFW firewall | apt |
| SSH server + ed25519 client key | apt + openssh_keypair |
| .bashrc | PATH for all tools + aliases |

### Post-setup playbook (`post-setup.yml`)

| Tool | Method | Requires |
|------|--------|----------|
| Portainer | Docker container on Netbird IP:9999 | Netbird connected |
| Telegram channel | Bot token env file | Bot token from BotFather |

## Aliases

| Alias | Command |
|-------|---------|
| `cld` | `claude --dangerously-skip-permissions` |

## Manual steps after provisioning

SSH into the server and complete these steps. They require interactive login and cannot be fully automated.

### 1. Netbird — join your network
```bash
netbird up
```
Follow the URL prompt to authenticate. Once connected, run `post-setup.yml` to start Portainer.

### 2. GitHub CLI — authenticate
```bash
gh auth login
```
Select GitHub.com, HTTPS, and follow the browser flow.

### 3. Claude Code — authenticate
```bash
claude
```
Follow the login prompt on first run.

### 4. Add SSH key to GitHub
```bash
cat ~/.ssh/id_ed25519.pub
```
Copy the output and add it at https://github.com/settings/keys

### 5. Telegram channel setup

The Telegram channel lets you message Claude from your phone via a Telegram bot.

#### a. Create a bot
1. Open [@BotFather](https://t.me/BotFather) in Telegram
2. Send `/newbot`, pick a display name and a username ending in `bot`
3. Copy the token BotFather returns

#### b. Save the token
Either pass it when running `post-setup.yml`:
```bash
ansible-playbook -i inventory.ini post-setup.yml --extra-vars "telegram_bot_token=YOUR_TOKEN"
```
Or configure it manually inside Claude Code:
```
/telegram:configure <YOUR_BOT_TOKEN>
```

#### c. Install the plugin
Inside Claude Code on the server:
```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install telegram@claude-plugins-official
/reload-plugins
```

#### d. Start Claude with the channel
```bash
claude --channels plugin:telegram@claude-plugins-official
# or with skip-permissions:
cld --channels plugin:telegram@claude-plugins-official
```

#### e. Pair your Telegram account
1. Send any message to your bot in Telegram — it replies with a pairing code
2. In Claude Code, run:
   ```
   /telegram:access pair <CODE>
   ```
3. Lock down access to only your account:
   ```
   /telegram:access policy allowlist
   ```

## Portainer

After running `post-setup.yml`, Portainer is available at:
```
http://<netbird-ip>:9999
```
On first visit, create an admin account. Only accessible over Netbird — not exposed on the public interface.

## Firewall rules

- **Default deny** all incoming on public interface
- **Allow** SSH (port 22) on public interface
- **Allow all** traffic on Netbird interface (`wt0`)
- **Allow all** outgoing
