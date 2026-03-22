# dev box scripts

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed locally
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) installed locally
- A Hetzner Cloud account

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

```bash
# 1. Provision the server
terraform init
terraform apply

# 2. Note the server IP from terraform output
terraform output server_ip

# 3. Run Ansible
cd ansible
cp inventory.ini.example inventory.ini
# Edit inventory.ini — replace YOUR_SERVER_IP with the IP from step 2
ansible-playbook -i inventory.ini playbook.yml

# Optionally pass Telegram bot token:
ansible-playbook -i inventory.ini playbook.yml --extra-vars "telegram_bot_token=YOUR_TOKEN"
```

## What gets installed

| Tool | Method |
|------|--------|
| Docker + Compose | apt (official repo) |
| Netbird | apt (official repo) |
| Rust + cargo | rustup |
| Go 1.26 | snap --classic |
| Node.js LTS | nvm |
| Bun | official install script |
| GitHub CLI | apt (official repo) |
| Claude Code | npm global |
| Language servers | npm/go/rustup (typescript, gopls, rust-analyzer, svelte, html/css/json, yaml, bash) |
| UFW firewall | apt |
| SSH server + client key | apt + openssh_keypair |

## Aliases

| Alias | Command |
|-------|---------|
| `cld` | `claude --dangerously-skip-permissions` |

## Manual steps after provisioning

These require interactive login and cannot be fully automated.

### 1. Netbird — join your network
```bash
netbird up
```
Follow the browser/URL prompt to authenticate.

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

#### b. Configure the token
If you didn't pass it via `--extra-vars` during ansible, run inside Claude Code:
```
/telegram:configure <YOUR_BOT_TOKEN>
```
This saves it to `~/.claude/channels/telegram/.env`.

#### c. Install the plugin (if ansible couldn't)
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

## Firewall rules

- **Default deny** all incoming on public interface
- **Allow** SSH (port 22) on public interface
- **Allow all** traffic on Netbird interface (`wt0`)
- **Allow all** outgoing
