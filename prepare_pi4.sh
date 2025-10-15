#!/usr/bin/env bash
set -Eeuo pipefail

# Fail nicely with an error message
trap 'code=$?; echo "[ERROR] $(date +"%F %T") Script failed at line $LINENO with exit code $code"; exit $code' ERR

log() { printf "\n[%s] %s\n" "$(date +'%F %T')" "$*"; }

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log "Sudo privileges required. You may be prompted for your password…"
    sudo -v
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${HOME}/src"
mkdir -p "$WORKDIR"

clone_or_update() {
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    log "Updating $(basename "$dest")…"
    git -C "$dest" pull --ff-only
  else
    log "Cloning $(basename "$dest")…"
    git clone "$url" "$dest"
  fi
}

main() {
  require_sudo

  log "Updating and upgrading packages…"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade

  log "Ensuring git is installed…"
  sudo apt install git -y

  # 1) Docker install from this repo
  if [ -f "${SCRIPT_DIR}/install_docker.sh" ]; then
    log "Running install_docker.sh from current repo…"
    chmod +x "${SCRIPT_DIR}/install_docker.sh"
    sudo bash "${SCRIPT_DIR}/install_docker.sh"
  else
    log "WARNING: install_docker.sh not found in ${SCRIPT_DIR}; skipping."
  fi

  # 2) Attach external disk (NTFS)
  local DISK_REPO_URL="https://github.com/ViliusU/attach-external-disk-drive-on-raspberry-pi.git"
  local DISK_DEST="${WORKDIR}/attach-external-disk-drive-on-raspberry-pi"
  clone_or_update "$DISK_REPO_URL" "$DISK_DEST"
  if [ -f "${DISK_DEST}/attach-external-ntfs.sh" ]; then
    log "Running attach-external-ntfs.sh…"
    chmod +x "${DISK_DEST}/attach-external-ntfs.sh"
    sudo bash "${DISK_DEST}/attach-external-ntfs.sh"
  else
    log "ERROR: attach-external-ntfs.sh not found in ${DISK_DEST}"
    exit 1
  fi

  # 3) Fan control
  local FAN_REPO_URL="https://github.com/ViliusU/Raspberry_Pi_Fan_Control_Setup_for_StromPi3_Case.git"
  local FAN_DEST="${WORKDIR}/Raspberry_Pi_Fan_Control_Setup_for_StromPi3_Case"
  clone_or_update "$FAN_REPO_URL" "$FAN_DEST"
  if [ -f "${FAN_DEST}/fan_control_install.sh" ]; then
    log "Running fan_control_install.sh…"
    chmod +x "${FAN_DEST}/fan_control_install.sh"
    sudo bash "${FAN_DEST}/fan_control_install.sh"
  else
    log "ERROR: fan_control_install.sh not found in ${FAN_DEST}"
    exit 1
  fi

  log "All done ✅"
  log "If the kernel or Docker was updated, a reboot may be recommended."
}

main "$@"
