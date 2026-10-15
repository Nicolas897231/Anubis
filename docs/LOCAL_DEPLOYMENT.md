# Local Deployment

This guide deploys ANUBIS on a clean Ubuntu Server LTS inside the LAN using Docker Compose, a private Docker network, and Caddy as the HTTPS reverse proxy for `https://anubis.snti.local`.

## Target Topology

```text
Windows client
  |
  | hosts or LAN DNS resolves anubis.snti.local
  v
Ubuntu Server LAN IP
  |
  v
Caddy :443
  |
  v
private Docker network
  |
  v
anubis-web Next.js standalone :3000
```

No LAN IP is hardcoded in code, Docker, Compose, Caddy, or Next.js. If the Ubuntu IP changes, update only the Windows `hosts` entry or LAN DNS record.

## Ubuntu Preparation

From the Ubuntu server:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg git
```

Install Docker Engine from Docker's official repository:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify:

```bash
docker --version
docker compose version
```

Optional non-root Docker usage:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

## Identify LAN IP

Use one of:

```bash
hostname -I
ip addr
```

Use that IP only in client DNS/hosts. Do not place it in project files.

## Firewall

Expose only SSH, HTTP, and HTTPS:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Do not expose `3000`, PostgreSQL, Supabase, Redis, or future internal services directly to the LAN.

## Project Setup

Copy or clone the project to the server, for example:

```bash
cd /opt
sudo mkdir -p anubis
sudo chown "$USER":"$USER" anubis
cd /opt/anubis
```

Then place the project contents there.

Create the environment file:

```bash
cp .env.example .env
```

Expected local values:

```text
APP_URL=https://anubis.snti.local
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

Only `NEXT_PUBLIC_*` values may be browser-visible. Future server-only secrets must not use that prefix and must not be committed.

## Start

```bash
docker compose -f compose.yaml up -d --build
```

Verify containers:

```bash
docker compose -f compose.yaml ps
docker compose -f compose.yaml logs -f anubis-web
```

`anubis-web` is reachable only inside the Docker network. Caddy publishes only ports `80` and `443`.

## Windows Hosts Resolution

On the Windows client, edit as Administrator:

```text
C:\Windows\System32\drivers\etc\hosts
```

Example only:

```text
192.168.1.50 anubis.snti.local
```

Replace the IP with the current Ubuntu LAN IP. For mobile devices, prefer router DNS, Pi-hole, AdGuard Home, or another LAN DNS server.

## Health Check

Before trusting the local CA:

```bash
curl -k https://anubis.snti.local/api/health
```

Expected response:

```json
{ "status": "ok" }
```

After trusting the Caddy CA:

```bash
curl https://anubis.snti.local/api/health
```

## Trust The Local HTTPS CA

Caddy uses `tls internal` for the `.local` lab hostname. Export the root CA:

```bash
docker compose -f compose.yaml cp caddy:/data/caddy/pki/authorities/local/root.crt ./anubis-local-ca.crt
```

Windows:

1. Open `anubis-local-ca.crt`.
2. Install Certificate.
3. Choose Local Machine.
4. Place it in Trusted Root Certification Authorities.

macOS:

1. Import `anubis-local-ca.crt` into System Keychain.
2. Set it to Always Trust.

Linux:

```bash
sudo cp anubis-local-ca.crt /usr/local/share/ca-certificates/anubis-local-ca.crt
sudo update-ca-certificates
```

Android:

1. Copy `anubis-local-ca.crt` to the device.
2. Install it from Settings > Security > Encryption and credentials.
3. Browser testing should trust the certificate after installation.

iPhone/iPad:

1. Send `anubis-local-ca.crt` to the device.
2. Install the profile from Settings.
3. Enable full trust in Settings > General > About > Certificate Trust Settings.

Do not permanently recommend bypassing certificate warnings.

## Auto-Start

Compose uses `restart: unless-stopped` for both services. Docker starts automatically after installation on Ubuntu, and containers return after reboot unless manually stopped:

```bash
sudo systemctl status docker
docker compose -f compose.yaml ps
```

## Operations

Stop:

```bash
docker compose -f compose.yaml down
```

Logs:

```bash
docker compose -f compose.yaml logs -f anubis-web
docker compose -f compose.yaml logs -f caddy
```

Update:

```bash
docker compose -f compose.yaml up -d --build
```

Rollback by source:

1. Restore the previous known-good source version.
2. Rebuild:

```bash
docker compose -f compose.yaml up -d --build
```

Rollback by image tag:

```bash
docker tag anubis-web:local anubis-web:previous
```

Then temporarily point `compose.yaml` to `anubis-web:previous` if a rebuild must be avoided.

## Production Notes For Later

- Replace `tls internal` with a real domain and ACME certificate before internet exposure.
- Add HSTS only after the final HTTPS hostname and certificate trust path are stable.
- Add managed secrets, image scanning, CI security gates, backups, restore tests, and monitoring before production.
- Do not publish internal databases or future storage services to the LAN.
