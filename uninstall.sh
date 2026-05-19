#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kilo End-User Uninstaller
# Removes Kilo CLI, config, PATH entries, and optionally Docker/Node.js
# Usage: curl -fsSL https://raw.githubusercontent.com/u-r-ai/kilo-end-user/54f2b6699f7a2e1801f8683bce9188b04bce8ef9/uninstall.sh | bash
# ============================================================================

REPO_SHA="54f2b6699f7a2e1801f8683bce9188b04bce8ef9"
SCRIPT_PID=$$

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }
header(){ echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }

# ============================================================================
# Sudo handling
# ============================================================================
setup_sudo() {
  if [ "$EUID" -eq 0 ]; then
    SUDO=""
    return
  fi

  if ! command -v sudo &>/dev/null; then
    err "sudo not found. Run this uninstaller as root."
    exit 1
  fi

  info "Requesting sudo password for uninstallation..."
  sudo -v
  SUDO="sudo"
}

# ============================================================================
# Remove Kilo CLI binaries
# ============================================================================
remove_kilo_binaries() {
  header "Removing Kilo CLI binaries"

  local kilo_bin=""
  kilo_bin=$(command -v kilo 2>/dev/null || true)

  if [ -n "$kilo_bin" ]; then
    # Kilo is usually installed via npm
    if command -v npm &>/dev/null; then
      info "Uninstalling Kilo CLI via npm..."
      npm uninstall -g @kilocode/cli 2>/dev/null && ok "Kilo CLI uninstalled via npm" || warn "npm uninstall failed, trying manual removal"
    fi
  fi

  # Remove any Kilo binary paths
  local kilo_paths=(
    "$HOME/.local/bin/kilo"
    "$HOME/.kilo/bin/kilo"
    "/usr/local/bin/kilo"
  )
  for p in "${kilo_paths[@]}"; do
    if [ -f "$p" ]; then
      rm -f "$p" 2>/dev/null && ok "Removed: $p" || warn "Could not remove: $p"
    fi
  done

  # Remove Kilo data directory
  if [ -d "$HOME/.kilo" ]; then
    rm -rf "$HOME/.kilo" 2>/dev/null && ok "Removed: $HOME/.kilo" || warn "Could not remove $HOME/.kilo"
  fi

  # Remove Kilo projects directory (ask first)
  if [ -d "$HOME/kilo-projects" ]; then
    echo ""
    warn "Kilo projects directory found at $HOME/kilo-projects"
    read -rp "Remove project files? (y/N): " remove_projects
    if [ "${remove_projects,,}" = "y" ]; then
      rm -rf "$HOME/kilo-projects" && ok "Removed: $HOME/kilo-projects"
    else
      info "Keeping: $HOME/kilo-projects"
    fi
  fi
}

# ============================================================================
# Remove Kilo configuration
# ============================================================================
remove_kilo_config() {
  header "Removing Kilo configuration"

  local config_dir="$HOME/.config/kilo"

  if [ -d "$config_dir" ]; then
    rm -rf "$config_dir" 2>/dev/null && ok "Removed: $config_dir" || warn "Could not remove $config_dir (may contain API keys)"
  else
    info "No Kilo config found at $config_dir"
  fi

  # Remove Docker sources list if added by installer
  if [ -f /etc/apt/sources.list.d/docker.list ] && grep -q "kilo" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
    # Actually Docker sources aren't Kilo-specific, so just note it
    warn "Docker APT source at /etc/apt/sources.list.d/docker.list was NOT removed (may be used by other software)"
  fi
}

# ============================================================================
# Remove PATH entries from shell config
# ============================================================================
remove_path_entries() {
  header "Removing Kilo CLI PATH entries from shell config"

  local path_pattern='export PATH="$HOME/.local/bin:$HOME/.kilo/bin:$PATH"'

  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
      # Create a backup before modifying
      local bak_file="${rc_file}.bak.$(date +%Y%m%d%H%M%S)"
      cp "$rc_file" "$bak_file"

      if grep -qF "$path_pattern" "$rc_file" 2>/dev/null; then
        # Use grep -v to remove the matching line
        local tmp_file
        tmp_file=$(mktemp)
        grep -vF "$path_pattern" "$rc_file" > "$tmp_file" || true
        mv "$tmp_file" "$rc_file"
        ok "Removed Kilo PATH entry from $rc_file (backup: $bak_file)"
      else
        info "No Kilo PATH entry found in $rc_file"
      fi
    fi
  done
}

# ============================================================================
# Remove Docker (optional)
# ============================================================================
remove_docker() {
  header "Docker"

  if command -v docker &>/dev/null; then
    echo ""
    warn "Docker is installed (it was installed as a dependency for Kilo)"
    read -rp "Remove Docker and all containers/images? (y/N): " remove_docker_yn
    if [ "${remove_docker_yn,,}" = "y" ]; then
      info "Removing Docker..."
      case "$(uname -s)" in
        Linux)
          # Stop Docker
          $SUDO systemctl stop docker 2>/dev/null || true
          $SUDO systemctl disable docker 2>/dev/null || true

          # Remove Docker packages
          if command -v apt &>/dev/null; then
            $SUDO apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
            $SUDO apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
          elif command -v dnf &>/dev/null; then
            $SUDO dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
          fi

          # Remove Docker data
          $SUDO rm -rf /var/lib/docker 2>/dev/null || true
          $SUDO rm -rf /var/lib/containerd 2>/dev/null || true
          $SUDO rm -f /etc/apt/keyrings/docker.gpg 2>/dev/null || true
          $SUDO rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
          ;;
      esac
      ok "Docker removed"
    else
      info "Keeping Docker"
    fi
  else
    info "Docker not installed, skipping"
  fi
}

# ============================================================================
# Remove Node.js (optional)
# ============================================================================
remove_nodejs() {
  header "Node.js"

  if command -v node &>/dev/null; then
    echo ""
    warn "Node.js is installed (it was installed as a dependency for Kilo)"
    read -rp "Remove Node.js? (y/N): " remove_node_yn
    if [ "${remove_node_yn,,}" = "y" ]; then
      info "Removing Node.js..."
      case "$(uname -s)" in
        Linux)
          if command -v apt &>/dev/null; then
            $SUDO apt-get remove -y nodejs 2>/dev/null || true
            $SUDO apt-get purge -y nodejs 2>/dev/null || true
            $SUDO apt-get autoremove -y 2>/dev/null || true
          elif command -v dnf &>/dev/null; then
            $SUDO dnf remove -y nodejs 2>/dev/null || true
          fi
          # Remove npm global packages
          rm -rf "$HOME/.npm" 2>/dev/null || true
          ;;
      esac
      ok "Node.js removed"
    else
      info "Keeping Node.js"
    fi
  else
    info "Node.js not installed, skipping"
  fi
}

# ============================================================================
# Cleanup temp files
# ============================================================================
cleanup() {
  header "Cleanup"
  info "Removing temporary files..."
  rm -f /tmp/kilo-install-* 2>/dev/null || true
  ok "Cleanup complete"
}

# ============================================================================
# Main
# ============================================================================
main() {
  header "Kilo CLI Uninstaller"
  echo ""
  warn "This will remove Kilo CLI and its configuration."
  warn "Your API keys stored in config files will be deleted."
  echo ""
  read -rp "Continue with uninstallation? (y/N): " confirm
  if [ "${confirm,,}" != "y" ]; then
    info "Uninstallation cancelled"
    exit 0
  fi

  setup_sudo
  remove_kilo_binaries
  remove_kilo_config
  remove_path_entries
  remove_docker
  remove_nodejs
  cleanup

  echo ""
  header "Uninstallation complete"
  echo ""
  info "Some changes (Docker group, shell PATH) may require a new terminal session."
  echo ""
}

main "$@"
