# OpenCode "On‑The‑Go" Setup Guide

This guide walks you through building a **mobile-first AI coding environment** using OpenCode running on a cloud VM. The goal is to let you:

- Start long-running coding tasks
- Leave your phone
- Get notified only when OpenCode needs input
- Reconnect instantly from anywhere

The architecture prioritizes **security, reliability, and low friction mobile access**.

---

# Architecture Overview

```
Phone (Termius + Tailscale)
        ↓ mosh
Private Network (Tailscale)
        ↓
Cloud VM
  - tmux (persistent sessions)
  - OpenCode
  - Notification plugin
```

Key design decisions:

✅ No public SSH  
✅ Sessions survive network drops  
✅ Push notifications when input is required  
✅ Disposable compute node

---

# Prerequisites

Before starting, ensure you have:

- A cloud provider account (Vultr, Hetzner, AWS, etc.)
- A phone (iOS or Android)
- Tailscale account
- SSH key
- OpenCode-compatible model API key
- A webhook-based notification service (ntfy, Pushover, Telegram bot, etc.)

---

# Step 1 — Create the VM

Recommended specs:

**Minimum:**

- 2 vCPU
- 4GB RAM

**Ideal:**

- 4 vCPU
- 8GB RAM

Ubuntu 22.04 or 24.04 is recommended.

After the VM is created, SSH into it once.

---

# Step 2 — Update System + Install Essentials

```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install curl git unzip jq tmux
```

These packages support plugins, shell scripting, and session persistence.

---

# Step 3 — Install Tailscale (Private Networking)

### Install

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Authenticate in the browser when prompted.

### Verify

```bash
tailscale ip -4
```

You should see an IP like:

```
100.x.y.z
```

Test connectivity from another device on your tailnet:

```bash
tailscale ping <hostname>
```

---

# Step 4 — Lock SSH to Tailscale Only (IMPORTANT)

Edit SSH config:

```bash
sudo nano /etc/ssh/sshd_config
```

Add:

```
ListenAddress 100.x.y.z
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

Now your server is not reachable from the public internet.

**Recommended extra protections:**

- Cloud firewall → block inbound SSH
- Disable password login
- Use SSH keys only

---

# Step 5 — Install mosh (Mobile-Friendly SSH)

mosh keeps sessions alive when:

- Switching WiFi ↔ LTE
- Phone sleeps
- Network drops

### Install

```bash
sudo apt -y install mosh
```

If using UFW:

```bash
sudo ufw allow 60000:61000/udp
```

(Preferably restrict this to the Tailscale interface.)

---

# Step 6 — Install OpenCode

```bash
curl -fsSL https://opencode.ai/install | bash
```

Verify:

```bash
opencode --version
```

If not found, restart your shell.

---

# Step 7 — Configure Persistent Sessions with tmux

Edit:

```bash
nano ~/.bashrc
```

Append:

```bash
# Auto-attach tmux on SSH
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
  tmux attach -t main 2>/dev/null || tmux new -s main
fi
```

Reload:

```bash
source ~/.bashrc
```

Now every login restores your workspace.

---

# Step 8 — Phone Setup (Termius + Tailscale)

## Install

- Tailscale
- Termius

Log into Tailscale on your phone.

## Add Host in Termius

Use:

- Host: `100.x.y.z`
- User: your VM user
- Auth: SSH key

## Connect via mosh

```bash
mosh user@100.x.y.z
```

If SSH runs on another port:

```bash
mosh --ssh="ssh -p 2222" user@100.x.y.z
```

You should land directly inside tmux.

## Multiple parallel OpenCode sessions (Android)

To run several OpenCode sessions at once from your phone (e.g. different projects), use **multiple Termius tabs** to the same VM and **tmux** on the VM so each tab has its own session.

### Option A — Multiple tabs, separate tmux sessions (recommended)

1. **On the VM:** Disable auto-attach so you can choose the tmux session per connection. Edit `~/.bashrc` and comment out or remove the block that attaches to `main`:

   ```bash
   # Comment out so you can create/attach to named sessions:
   # if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
   #   tmux attach -t main 2>/dev/null || tmux new -s main
   # fi
   ```

2. **On the phone (Termius):**
   - Open a **new tab** and connect again: `mosh user@100.x.y.z`.
   - In **tab 1:** `tmux new -s project-a` then `cd ~/project-a && opencode ...`
   - In **tab 2:** `tmux new -s project-b` then `cd ~/project-b && opencode ...`
   - Reconnect later: `tmux attach -t project-a` or `tmux attach -t project-b`.

Each tab is a separate connection; each can run a different named tmux session and a different OpenCode run.

### Option B — One tab, multiple tmux windows

Keep the existing auto-attach to `main`. Use one Termius connection and tmux windows inside it:

- Create a new window: **`Ctrl+b c`**
- In each window: `cd ~/project-x && opencode ...`
- Switch windows: **`Ctrl+b n`** (next), **`Ctrl+b p`** (previous), **`Ctrl+b 0`** … **`Ctrl+b 9`** (by number)

| Goal                                                | On phone                                          | On VM                                                                                |
| --------------------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Several independent OpenCode sessions (per project) | Multiple Termius tabs, each `mosh user@100.x.y.z` | Option A: disable auto-attach; in each tab `tmux new -s <name>` then run OpenCode    |
| One connection, multiple tasks                      | One Termius tab                                   | Option B: one session, use tmux windows (`Ctrl+b c`) and run OpenCode in each window |

# VM Security Hardening Guide

**OS:** Ubuntu LTS
**Tailscale IP:** 100.xxx.xx.xx
**Audit date:** 2026-02-13

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [SSH Hardening](#2-ssh-hardening)
3. [Firewall Configuration (UFW)](#3-firewall-configuration-ufw)
4. [Fail2ban Intrusion Prevention](#4-fail2ban-intrusion-prevention)
5. [Kernel Network Hardening](#5-kernel-network-hardening)
6. [Tailscale Configuration](#6-tailscale-configuration)
7. [Ongoing Maintenance](#7-ongoing-maintenance)
8. [Verification Commands](#8-verification-commands)
9. [Emergency Recovery](#9-emergency-recovery)

---

## 1. Architecture Overview

The VM is designed to be accessible **only** through Tailscale (mesh VPN). All public-facing services are blocked. The access path is:

```
You (Termius) --> Tailscale Network --> 100.xxx.xx.xx:22 --> VM
```

No traffic from the public internet should reach any service on the VM. This is enforced at three layers:

| Layer                   | Mechanism             | What it does                                          |
| ----------------------- | --------------------- | ----------------------------------------------------- |
| 1. Service binding      | `ssh.socket` override | SSH only listens on the Tailscale interface           |
| 2. Firewall             | UFW                   | Drops all incoming traffic except SSH on `tailscale0` |
| 3. Intrusion prevention | fail2ban              | Bans IPs after repeated failed auth attempts          |

---

## 2. SSH Hardening

### 2.1 Restrict SSH to Tailscale interface only

Ubuntu 24.04 uses **systemd socket activation** for SSH. The `ListenAddress` directive in `/etc/ssh/sshd_config` is ignored because `ssh.socket` controls which address SSH binds to. You must override the socket unit.

**Config file:** `/etc/systemd/system/ssh.socket.d/override.conf`

```ini
[Socket]
ListenStream=
ListenStream=100.xxx.xx.xx:22
```

> The empty `ListenStream=` line is **required**. It clears the default `0.0.0.0:22` and `[::]:22` entries before setting the Tailscale-only address.

**Apply changes:**

```bash
systemctl daemon-reload
systemctl restart ssh.socket
```

**Verify:**

```bash
ss -tlnp | grep ":22"
# Expected: LISTEN on 100.xxx.xx.xx:22 ONLY
# Bad: LISTEN on 0.0.0.0:22 means the override is not working
```

### 2.2 Disable password authentication

Password auth over SSH is vulnerable to brute-force attacks. Use key-based authentication only.

**Config file:** `/etc/ssh/sshd_config.d/99-hardening.conf`

```
PasswordAuthentication no
PermitRootLogin prohibit-password
X11Forwarding no
MaxAuthTries 3
```

**Why each setting matters:**

| Setting                  | Value               | Reason                                                   |
| ------------------------ | ------------------- | -------------------------------------------------------- |
| `PasswordAuthentication` | `no`                | Prevents brute-force password attacks entirely           |
| `PermitRootLogin`        | `prohibit-password` | Root can only log in with SSH keys, not passwords        |
| `X11Forwarding`          | `no`                | Unnecessary on a headless server, reduces attack surface |
| `MaxAuthTries`           | `3`                 | Limits auth attempts per connection (default is 6)       |

**Apply changes:**

```bash
systemctl restart ssh
```

### 2.3 Fix conflicting cloud-init SSH config

Cloud-init ships `/etc/ssh/sshd_config.d/50-cloud-init.conf` with `PasswordAuthentication yes`. The `99-hardening.conf` file overrides it (files load alphabetically), but this is fragile. If cloud-init regenerates its config, it could re-enable password auth.

**Fix option A -- overwrite the cloud-init file:**

```bash
echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/50-cloud-init.conf
systemctl restart ssh
```

**Fix option B -- prevent cloud-init from managing SSH password auth:**

```bash
cat > /etc/cloud/cloud.cfg.d/99-disable-ssh-pwauth.cfg << 'EOF'
ssh_pwauth: false
EOF
```

### 2.4 SSH key management

Your authorized keys are stored in `/root/.ssh/authorized_keys`.

**Add a new key:**

```bash
echo "ssh-ed25519 AAAA... user@host" >> /root/.ssh/authorized_keys
```

**Remove a key:** Edit the file and delete the corresponding line.

**Correct permissions (required for SSH to accept the keys):**

```bash
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh
```

> If permissions are wrong, SSH will silently refuse key auth and fall back to password auth (which is now disabled), locking you out.

---

## 3. Firewall Configuration (UFW)

### 3.1 Current rules

```
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22 on tailscale0           ALLOW IN    Anywhere
22 (v6) on tailscale0      ALLOW IN    Anywhere (v6)
```

This means:

- All incoming traffic is **denied by default**
- SSH (port 22) is allowed **only** on the `tailscale0` interface
- All outgoing traffic is allowed (so the VM can reach the internet for updates, etc.)

### 3.2 How this was configured

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow in on tailscale0 to any port 22
ufw enable
```

### 3.3 Adding new rules

If you need to expose additional services (e.g., a web server for development), always restrict to the Tailscale interface:

```bash
# Allow a web server only via Tailscale
ufw allow in on tailscale0 to any port 8080

# NEVER do this (exposes to public internet):
# ufw allow 8080
```

**View current rules:**

```bash
ufw status verbose
```

**Remove a rule:**

```bash
ufw status numbered
ufw delete <rule_number>
```

### 3.4 Important notes

- UFW persists across reboots automatically.
- If you lock yourself out, you can access the VM via the Hetzner web console and run `ufw disable`.
- UFW works alongside Tailscale's own iptables rules without conflict.

---

## 4. Fail2ban Intrusion Prevention

### 4.1 What it does

Fail2ban monitors SSH auth logs and temporarily bans IP addresses that have too many failed login attempts. This is defense-in-depth -- even if SSH is only on Tailscale, fail2ban adds another layer.

### 4.2 Check status

```bash
# Overall status
systemctl status fail2ban

# SSH jail status (banned IPs, fail counts)
fail2ban-client status sshd
```

### 4.3 Configuration

The default config is at `/etc/fail2ban/jail.conf`. Do not edit this file directly. Create overrides in `/etc/fail2ban/jail.local`:

```bash
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 5
findtime = 600
bantime = 3600
EOF
```

| Setting    | Value  | Meaning                     |
| ---------- | ------ | --------------------------- |
| `maxretry` | `5`    | Ban after 5 failed attempts |
| `findtime` | `600`  | Within a 10-minute window   |
| `bantime`  | `3600` | Ban lasts 1 hour            |

**Apply changes:**

```bash
systemctl restart fail2ban
```

### 4.4 Manual ban/unban

```bash
# Ban an IP
fail2ban-client set sshd banip 1.2.3.4

# Unban an IP
fail2ban-client set sshd unbanip 1.2.3.4
```

---

## 5. Kernel Network Hardening

### 5.1 Sysctl settings

These kernel parameters disable ICMP redirect handling, which prevents certain network-level MITM attacks.

**Config file:** `/etc/sysctl.d/99-security.conf`

```
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
```

**Apply:**

```bash
sysctl --system
```

**Verify:**

```bash
sysctl net.ipv4.conf.all.accept_redirects   # should be 0
sysctl net.ipv4.conf.all.send_redirects      # should be 0
sysctl net.ipv6.conf.all.accept_redirects    # should be 0
```

### 5.2 Already-secure defaults (no action needed)

These are already set correctly on this system:

| Parameter                               | Value | Meaning                 |
| --------------------------------------- | ----- | ----------------------- |
| `kernel.randomize_va_space`             | `2`   | Full ASLR enabled       |
| `net.ipv4.tcp_syncookies`               | `1`   | SYN flood protection    |
| `net.ipv4.ip_forward`                   | `0`   | IP forwarding disabled  |
| `net.ipv4.conf.all.accept_source_route` | `0`   | Source routing rejected |

---

## 6. Tailscale Configuration

### 6.1 Current state

| Setting             | Value            | Notes                                                       |
| ------------------- | ---------------- | ----------------------------------------------------------- |
| Tailscale IP        | `xxx.xxx.xx.xxx` | Stable across reboots                                       |
| RunSSH              | `false`          | Tailscale SSH is off (using standard SSH, which is correct) |
| ShieldsUp           | `false`          | Other tailnet devices can connect inbound                   |
| NoStatefulFiltering | `true`           | Stateful filtering disabled                                 |
| Auto-updates        | Enabled          | Tailscale updates itself                                    |
| Exit node           | Not configured   | This VM is not an exit node                                 |

### 6.2 Optional: Enable ShieldsUp

If you only need to SSH **into** this VM (not accept other Tailscale connections), ShieldsUp blocks all unsolicited inbound Tailscale traffic:

```bash
tailscale set --shields-up=true
```

> Note: This does NOT affect your SSH access via Termius as long as you initiate the connection from your device. It blocks other tailnet devices from initiating connections to this VM for services other than what Tailscale explicitly allows.

### 6.3 Tailscale ACLs (access control lists)

For stronger access control, configure ACLs in the Tailscale admin console (https://login.tailscale.com/admin/acls). Example policy that restricts SSH access to only your devices:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["nejcm@github"],
      "dst": ["ubuntu-4gb-hel1-3:22"]
    }
  ]
}
```

### 6.4 Tailscale key expiry

By default, Tailscale node keys expire. If your VM loses Tailscale connectivity, check:

```bash
tailscale status
```

If the key has expired, re-authenticate:

```bash
tailscale up --auth-key=<key>
# Or interactive:
tailscale up
```

---

## 7. Ongoing Maintenance

### 7.1 System updates

```bash
# Check for updates
apt update && apt list --upgradable

# Apply all updates
apt upgrade -y

# Apply only security updates
apt install -y unattended-upgrades
unattended-upgrades --dry-run  # preview
unattended-upgrades             # apply
```

Unattended-upgrades is already enabled and will automatically install security updates.

### 7.2 Monitor auth logs

```bash
# Recent failed login attempts
grep "Failed password" /var/log/auth.log | tail -20

# Recent successful logins
grep "Accepted" /var/log/auth.log | tail -20

# Count failed attempts by IP
grep "Failed password" /var/log/auth.log | grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | head -10
```

### 7.3 Monitor listening services

Periodically verify no unexpected services are exposed:

```bash
# All listening TCP services
ss -tlnp

# Expected output should only show:
# - 100.xxx.xx.xx:22 (SSH on Tailscale)
# - 127.0.0.53:53 (systemd-resolved, localhost only)
# - Tailscale internal ports on 100.x.x.x
```

### 7.4 Check for rootkits (optional)

```bash
apt install -y rkhunter
rkhunter --update
rkhunter --check --skip-keypress
```

---

## 8. Verification Commands

Run these commands to verify the full security posture at any time:

```bash
echo "=== SSH Listening Address ==="
ss -tlnp | grep ":22"
# Expected: 100.xxx.xx.xx:22 only

echo "=== SSH Config ==="
sshd -T 2>/dev/null | grep -E "^(passwordauthentication|permitrootlogin|x11forwarding|maxauthtries)"
# Expected: passwordauthentication no, permitrootlogin prohibit-password,
#           x11forwarding no, maxauthtries 3

echo "=== Firewall ==="
ufw status
# Expected: active, deny incoming, allow 22 on tailscale0

echo "=== Fail2ban ==="
fail2ban-client status sshd
# Expected: active jail with ban counts

echo "=== Tailscale ==="
tailscale status
# Expected: online, showing your tailnet devices

echo "=== Kernel Hardening ==="
sysctl net.ipv4.conf.all.accept_redirects net.ipv4.conf.all.send_redirects
# Expected: both 0

echo "=== Open Ports (public interface) ==="
ss -tlnp | grep -v "100.xxx.xx.xx\|127.0.0\|::1\|tailscale"
# Expected: empty (nothing exposed publicly)
```

---

## 9. Emergency Recovery

### 9.1 Locked out of SSH

If you lose SSH access (e.g., key issues, firewall misconfiguration):

1. **Hetzner web console:** Log into https://console.hetzner.cloud, select your server, and open the VNC/web console. You can log in with the root password directly.
2. **Disable UFW:** `ufw disable`
3. **Reset SSH to listen on all interfaces:**
   ```bash
   rm /etc/systemd/system/ssh.socket.d/override.conf
   systemctl daemon-reload
   systemctl restart ssh.socket
   ```
4. **Re-enable password auth temporarily:**
   ```bash
   rm /etc/ssh/sshd_config.d/99-hardening.conf
   systemctl restart ssh
   ```
5. Fix the root cause, then re-apply hardening.

### 9.2 Tailscale goes down

If Tailscale loses connectivity:

```bash
# Check status
tailscale status

# Restart
systemctl restart tailscaled

# Re-authenticate if key expired
tailscale up
```

If Tailscale is completely broken and you need SSH access, use the Hetzner web console (Section 9.1) to temporarily re-expose SSH.

### 9.3 fail2ban bans your own IP

```bash
# From another session or Hetzner console
fail2ban-client set sshd unbanip <your_ip>
```

---

## Appendix: File Reference

| File                                             | Purpose                                       |
| ------------------------------------------------ | --------------------------------------------- |
| `/etc/ssh/sshd_config`                           | Main SSH config (do not edit, use drop-ins)   |
| `/etc/ssh/sshd_config.d/99-hardening.conf`       | SSH hardening overrides                       |
| `/etc/ssh/sshd_config.d/50-cloud-init.conf`      | Cloud-init SSH config (should be neutralized) |
| `/etc/systemd/system/ssh.socket.d/override.conf` | Forces SSH to Tailscale interface only        |
| `/root/.ssh/authorized_keys`                     | SSH public keys allowed to log in             |
| `/etc/ufw/`                                      | UFW firewall configuration                    |
| `/etc/fail2ban/jail.local`                       | Fail2ban custom config                        |
| `/etc/sysctl.d/99-security.conf`                 | Kernel network hardening                      |
| `/var/log/auth.log`                              | SSH authentication logs                       |

---

# Step 9 — Authenticate OpenCode

Start OpenCode:

```bash
opencode
```

Then run:

```
/connect
```

Select your provider and paste your API key.

Credentials are stored locally on the VM.

---

# Step 10 — Configure Project Permissions

Create an OpenCode config inside your repo:

```bash
nano opencode.json
```

Example:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "question": "allow",
    "bash": "ask",
    "edit": "ask"
  }
}
```

Why this matters:

- `question` enables OpenCode to ask for input
- `ask` prevents dangerous automation

---

# Step 11 — Push Notifications When OpenCode Needs Input

This is the feature that makes mobile workflows practical.

We will create a plugin that listens for the `question` tool and triggers a webhook.

---

## 11.1 Setup Knock Webhook (Recommended)

Knock provides production-grade push notifications across mobile, email, Slack, and more. We will trigger a Knock workflow via its **incoming webhook** whenever OpenCode asks a question.

### Create a Knock Account

1. Go to **https://knock.app** and create an account.
2. Create a new **environment** (development is fine to start).

---

### Create a Workflow

Inside Knock:

1. Navigate to **Workflows** → **Create workflow**.
2. Choose **Trigger → Incoming Webhook**.
3. Add a **Push notification** step (or any channel you prefer).
4. Customize the notification template. Example:

**Title:**

```
OpenCode needs input
```

**Body:**

```
{{data.message}}
```

Publish the workflow.

---

### Copy the Webhook URL

Knock will generate a webhook like:

```
https://api.knock.app/v1/workflows/<workflow-key>/trigger
```

Copy it.

---

### Store Webhook Securely on the VM

Add it to your shell config:

```bash
nano ~/.bashrc
```

Add:

```bash
export OPENCODE_NOTIFY_WEBHOOK="https://api.knock.app/v1/workflows/<workflow-key>/trigger"
export KNOCK_API_KEY="YOUR_KNOCK_SECRET_KEY"
```

Reload:

```bash
source ~/.bashrc
```

---

## 11.2 Create Plugin Directory

```bash
mkdir -p ~/.config/opencode/plugins
```

---

## 11.3 Create Plugin

```bash
nano ~/.config/opencode/plugins/notify-question.js
```

Paste:

```javascript
export const NotifyOnQuestion = async ({ project, $, directory }) => {
  const webhook = process.env.OPENCODE_NOTIFY_WEBHOOK;
  if (!webhook) return {};

  const projectName = project?.name || "opencode";

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "question") return;

      const payload = {
        message: `[${projectName}] OpenCode needs input`,
        cwd: directory,
        args: output?.args ?? null,
      };

      await $`curl -fsS -X POST ${webhook} \
        -H "content-type: application/json" \
        -d ${JSON.stringify(payload)}`;
    },

    event: async ({ event }) => {
      if (event.type === "session.idle" || event.type === "session.error") {
        const payload = {
          message: `[${projectName}] ${event.type}`,
          cwd: directory,
        };

        await $`curl -fsS -X POST ${webhook} \
          -H "content-type: application/json" \
          -d ${JSON.stringify(payload)}`;
      }
    },
  };
};
```

Restart OpenCode after creating the plugin.

---

# Step 12 — Test the Notification Path

Ask OpenCode to request input deliberately:

> "Before starting, ask me which package manager to use."

If configured correctly:

✅ Phone buzzes  
✅ You reconnect  
✅ Answer the question  
✅ Agent continues

---

# Step 13 — Optional: Run OpenCode Web UI (No SSH Required)

Start server:

```bash
OPENCODE_SERVER_PASSWORD='strong-password' \
opencode web --hostname 100.x.y.z --port 4096
```

Then open on your phone:

```
http://100.x.y.z:4096
```

**IMPORTANT:** Never expose this publicly.
Bind only to Tailscale.

---

# Daily Workflow

1. Connect via mosh
2. Land in tmux
3. Run OpenCode
4. Start a long task
5. Put phone away
6. Get notified only when needed

This enables a highly asynchronous development style.

---

# Strongly Recommended Advanced Practices

## Use Disposable VMs

Treat the machine as expendable.
Never store production secrets.

## Use Git Worktrees

Run multiple agents safely:

```bash
git worktree add ../feature-x feature-x
```

Each worktree → separate tmux window → separate agent.

## Add Cost Control

Use provider auto-shutdown or scripts to stop idle machines.

## Deterministic Dev Ports

Avoid collisions by hashing branch names.

---

# Troubleshooting

## No notifications

Check:

```bash
echo $OPENCODE_NOTIFY_WEBHOOK
```

Restart OpenCode after plugin creation.

Ensure the task actually triggers a question.

---

## Plugin not loading

Verify location:

```
~/.config/opencode/plugins/
```

Restart OpenCode.

---

## Connection drops

Use mosh, not plain SSH.

---

# Final Result

You now have a **mobile-native AI coding environment** that is:

✅ Secure  
✅ Persistent  
✅ Interrupt-driven  
✅ Cloud-based  
✅ Scalable to multiple agents

Once you use this workflow for a few days, it becomes extremely difficult to go back to laptop-only agent execution.

---

If you want, I can next help you build a **one-tap phone shortcut** that:

- Starts the VM
- Waits for Tailscale
- Launches Termius

Turning this into a near-frictionless "spawn agent anywhere" setup.
