# dev box scripts

## Quick start

```bash
# 1. Provision the server
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Hetzner token and SSH key
terraform init && terraform apply

# 2. Run Ansible
cd ../ansible
cp inventory.ini.example inventory.ini
# Edit inventory.ini with your server IP
ansible-playbook -i inventory.ini playbook.yml
```

## Manual steps after provisioning

These require interactive login and cannot be fully automated:

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

## Firewall rules

- **Default deny** all incoming on public interface
- **Allow** SSH (port 22) on public interface
- **Allow all** traffic on Netbird interface (`wt0`)
- **Allow all** outgoing
