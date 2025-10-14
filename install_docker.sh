#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# install-docker.sh
# Installs Docker Engine & Docker Compose plugin on Raspberry Pi OS, non-interactively.
# -----------------------------------------------------------------------------

# 1. Must be root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo: sudo $0"
  exit 1
fi

# 2. Detect CPU architecture
arch=$(dpkg --print-architecture)     # armhf or arm64
echo "Detected architecture: $arch"

# 3. Install prerequisites & prepare keyrings dir
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release
install -m0755 -d /etc/apt/keyrings

# 4. Fetch & install Docker’s GPG key (overwrite any existing copy)
rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --batch --dearmor -o /etc/apt/keyrings/docker.gpg

# 5. Add Docker APT repository
codename=$(lsb_release -cs)           # e.g. bookworm
echo \
  "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  ${codename} stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6. Install Docker Engine & Compose plugin
apt-get update -y
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 7. Enable & start Docker service
systemctl enable docker
systemctl start docker

# 8. Add your sudo user to 'docker' group (so you can run docker without sudo)
if [ -n "${SUDO_USER-}" ] && id "${SUDO_USER}" &>/dev/null; then
  usermod -aG docker "${SUDO_USER}"
  echo "→ Added ${SUDO_USER} to the docker group. Log out/in to apply."
fi

# 9. Verify installation
echo
echo "→ Docker version: $(docker --version)"
echo "→ Docker Compose version: $(docker compose version)"
echo
echo "✅ Installation complete! Now you can:"
echo "   cd /path/to/your/project"
echo "   docker compose up -d"
