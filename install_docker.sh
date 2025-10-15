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

# 8. Add a non-root user to the 'docker' group (so they can run docker without sudo)
resolve_target_user() {
  # 1) Explicit override via env
  if [ -n "${TARGET_USER:-}" ] && id "${TARGET_USER}" &>/dev/null && [ "${TARGET_USER}" != "root" ]; then
    echo "${TARGET_USER}"; return
  fi
  # 2) The sudo caller, if present and not root
  if [ -n "${SUDO_USER:-}" ] && id "${SUDO_USER}" &>/dev/null && [ "${SUDO_USER}" != "root" ]; then
    echo "${SUDO_USER}"; return
  fi
  # 3) Login name from controlling TTY
  if login_user="$(logname 2>/dev/null)"; then
    if [ -n "${login_user}" ] && id "${login_user}" &>/dev/null && [ "${login_user}" != "root" ]; then
      echo "${login_user}"; return
    fi
  fi
  # 4) Common Debian/RPi: first human user is uid 1000
  if u1000="$(id -nu 1000 2>/dev/null)"; then
    if [ -n "${u1000}" ] && [ "${u1000}" != "root" ]; then
      echo "${u1000}"; return
    fi
  fi
  # 5) As a last resort, try USER if not root
  if [ -n "${USER:-}" ] && [ "${USER}" != "root" ] && id "${USER}" &>/dev/null; then
    echo "${USER}"; return
  fi
  echo ""
}

target_user="$(resolve_target_user)"
if [ -n "${target_user}" ]; then
  # ensure docker group exists (normally created by the package)
  getent group docker >/dev/null || groupadd docker || true
  usermod -aG docker "${target_user}"
  echo "→ Added ${target_user} to the docker group. Log out/in to apply."
else
  echo "→ Skipping docker group membership: no suitable non-root user detected."
  echo "   Later you can run: sudo usermod -aG docker <username>"
fi


# 9. Verify installation
echo
echo "→ Docker version: $(docker --version)"
echo "→ Docker Compose version: $(docker compose version)"
echo
echo "✅ Installation complete! Now you can:"
echo "   cd /path/to/your/project"
echo "   docker compose up -d"
