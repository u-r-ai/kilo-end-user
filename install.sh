#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kilo End-User Installer
# One-command setup for Kilo CLI with pre-configured Indonesian AI agent
# Usage: curl -fsSL https://raw.githubusercontent.com/u-r-ai/kilo-end-user/54f2b6699f7a2e1801f8683bce9188b04bce8ef9/install.sh | bash
# ============================================================================

REPO_SHA="54f2b6699f7a2e1801f8683bce9188b04bce8ef9"
REPO_RAW="https://raw.githubusercontent.com/u-r-ai/kilo-end-user/$REPO_SHA"
KILO_CONFIG_DIR="$HOME/.config/kilo"
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
# Argument parsing for non-interactive mode
# ============================================================================
NON_INTERACTIVE=false

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --non-interactive)
        NON_INTERACTIVE=true
        shift
        ;;
      --provider)
        if [ -z "${2:-}" ]; then
          err "--provider requires a value (deepseek, anthropic, openai, gemini, openrouter)"
          exit 1
        fi
        PROVIDER_ID="$2"
        shift 2
        ;;
      --api-key)
        if [ -z "${2:-}" ]; then
          err "--api-key requires a value"
          exit 1
        fi
        API_KEY="$2"
        shift 2
        ;;
      --model)
        if [ -z "${2:-}" ]; then
          err "--model requires a value"
          exit 1
        fi
        DEFAULT_MODEL="$2"
        shift 2
        ;;
      *)
        err "Argumen tidak dikenal: $1"
        echo "Penggunaan: curl -fsSL .../install.sh | bash -s -- [options]"
        echo ""
        echo "  --non-interactive     Non-interactive mode (no prompts)"
        echo "  --provider <name>     AI provider: deepseek, anthropic, openai, gemini, openrouter"
        echo "  --api-key <key>       API key for the provider"
        echo "  --model <model>       Model name (defaults to provider's default)"
        exit 1
        ;;
    esac
  done

  if [ "$NON_INTERACTIVE" = true ]; then
    if [ -z "${PROVIDER_ID:-}" ]; then
      err "Non-interactive mode requires --provider"
      exit 1
    fi
    if [ -z "${API_KEY:-}" ]; then
      err "Non-interactive mode requires --api-key"
      exit 1
    fi

    # Set default model if not provided
    case "${PROVIDER_ID:-}" in
      deepseek)   PROVIDER_NAME="DeepSeek";   DEFAULT_MODEL="${DEFAULT_MODEL:-deepseek-chat}";;
      anthropic)  PROVIDER_NAME="Anthropic";  DEFAULT_MODEL="${DEFAULT_MODEL:-claude-sonnet-4}";;
      openai)     PROVIDER_NAME="OpenAI";     DEFAULT_MODEL="${DEFAULT_MODEL:-gpt-4o}";;
      gemini)     PROVIDER_NAME="Gemini";     DEFAULT_MODEL="${DEFAULT_MODEL:-gemini-2.5-flash}";;
      openrouter) PROVIDER_NAME="OpenRouter"; DEFAULT_MODEL="${DEFAULT_MODEL:-anthropic/claude-sonnet-4}";;
      *)
        err "Provider tidak dikenal: $PROVIDER_ID. Gunakan: deepseek, anthropic, openai, gemini, openrouter"
        exit 1
        ;;
    esac
  fi
}

# ============================================================================
# Sudo handling
# ============================================================================
setup_sudo() {
  if [ "$EUID" -eq 0 ]; then
    SUDO=""
    return
  fi

  if ! command -v sudo &>/dev/null; then
    err "sudo tidak ditemukan. Jalankan installer ini sebagai root."
    exit 1
  fi

  info "Meminta password sudo untuk instalasi..."
  sudo -v

  # Keep sudo alive in background (capped at 30 minutes)
  local sudo_keepalive_max=30
  local sudo_count=0
  while [ $sudo_count -lt $sudo_keepalive_max ]; do
    sudo -n true 2>/dev/null || break
    sleep 60
    kill -0 "$SCRIPT_PID" 2>/dev/null || exit
    sudo_count=$((sudo_count + 1))
  done &
  SUDO_PID=$!

  if [ $sudo_count -ge $sudo_keepalive_max ]; then
    warn "Sudo keep-alive telah berjalan 30 menit. Jika instalasi masih berlangsung, Anda mungkin perlu memasukkan password sudo kembali."
  fi
  SUDO="sudo"
}

# ============================================================================
# Distro detection
# ============================================================================
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-$DISTRO_ID}"
  else
    DISTRO_ID="unknown"
    DISTRO_LIKE="unknown"
  fi

  # Validate DISTRO_ID: only alphanumeric and hyphens allowed
  if ! echo "$DISTRO_ID" | grep -qE '^[a-zA-Z][a-zA-Z0-9_-]*$'; then
    err "Nilai ID tidak valid dari /etc/os-release: '$DISTRO_ID'"
    exit 1
  fi

  case "$DISTRO_ID" in
    ubuntu|debian|linuxmint|pop)
      PKG_UPDATE="$SUDO apt-get update -y"
      PKG_INSTALL="$SUDO apt-get install -y"
      PKG_MANAGER="apt"
      ;;
    fedora|rhel|centos|rocky|alma)
      PKG_UPDATE="$SUDO dnf check-update -y || true"
      PKG_INSTALL="$SUDO dnf install -y"
      PKG_MANAGER="dnf"
      ;;
    arch|manjaro|endeavouros)
      PKG_UPDATE="$SUDO pacman -Sy"
      PKG_INSTALL="$SUDO pacman -S --noconfirm"
      PKG_MANAGER="pacman"
      ;;
    opensuse*|sles)
      PKG_UPDATE="$SUDO zypper refresh"
      PKG_INSTALL="$SUDO zypper install -y"
      PKG_MANAGER="zypper"
      ;;
    *)
      if echo "$DISTRO_LIKE" | grep -qi "debian\|ubuntu"; then
        PKG_UPDATE="$SUDO apt-get update -y"
        PKG_INSTALL="$SUDO apt-get install -y"
        PKG_MANAGER="apt"
      elif echo "$DISTRO_LIKE" | grep -qi "fedora\|rhel"; then
        PKG_UPDATE="$SUDO dnf check-update -y || true"
        PKG_INSTALL="$SUDO dnf install -y"
        PKG_MANAGER="dnf"
      elif echo "$DISTRO_LIKE" | grep -qi "arch"; then
        PKG_UPDATE="$SUDO pacman -Sy"
        PKG_INSTALL="$SUDO pacman -S --noconfirm"
        PKG_MANAGER="pacman"
      else
        err "Distro tidak dideteksi: $DISTRO_ID. Mendukung: Ubuntu, Debian, Fedora, Arch, openSUSE."
        exit 1
      fi
      ;;
  esac

  info "Terdeteksi distro: $DISTRO_ID (package manager: $PKG_MANAGER)"
}

# ============================================================================
# Install prerequisites
# ============================================================================
install_prerequisites() {
  header "Memeriksa dan menginstal prerequisites"

  local packages=()

  if ! command -v curl &>/dev/null; then
    packages+=("curl")
  else
    ok "curl sudah terinstall"
  fi

  if ! command -v git &>/dev/null; then
    packages+=("git")
  else
    ok "git sudah terinstall"
  fi

  if ! command -v unzip &>/dev/null; then
    packages+=("unzip")
  else
    ok "unzip sudah terinstall"
  fi

  if [ ${#packages[@]} -gt 0 ]; then
    info "Menginstall: ${packages[*]}"
    $PKG_UPDATE
    $PKG_INSTALL "${packages[@]}"
    ok "Prerequisites terinstall"
  fi
}

# ============================================================================
# Install Node.js LTS
# ============================================================================
install_nodejs() {
  header "Memeriksa Node.js"

  if command -v node &>/dev/null; then
    local node_version
    node_version=$(node --version 2>/dev/null || echo "none")
    ok "Node.js sudah terinstall: $node_version"
    return
  fi

  info "Menginstall Node.js LTS..."

  local nodesource_script
  case "$PKG_MANAGER" in
    apt)
      nodesource_script=$(mktemp /tmp/kilo-install-nodesource.XXXXXX)
      curl -fsSL -o "$nodesource_script" https://deb.nodesource.com/setup_lts.x
      if [ ! -s "$nodesource_script" ]; then
        err "Gagal mengunduh NodeSource setup script (file kosong)"
        rm -f "$nodesource_script"
        exit 1
      fi
      if ! head -5 "$nodesource_script" | grep -qi "bash\|nodesource\|nodejs" 2>/dev/null; then
        err "NodeSource setup script tidak valid (header tidak dikenal)"
        rm -f "$nodesource_script"
        exit 1
      fi
      $SUDO bash "$nodesource_script"
      rm -f "$nodesource_script"
      $SUDO apt-get install -y nodejs
      ;;
    dnf)
      nodesource_script=$(mktemp /tmp/kilo-install-nodesource.XXXXXX)
      curl -fsSL -o "$nodesource_script" https://rpm.nodesource.com/setup_lts.x
      if [ ! -s "$nodesource_script" ]; then
        err "Gagal mengunduh NodeSource setup script (file kosong)"
        rm -f "$nodesource_script"
        exit 1
      fi
      if ! head -5 "$nodesource_script" | grep -qi "bash\|nodesource\|nodejs" 2>/dev/null; then
        err "NodeSource setup script tidak valid (header tidak dikenal)"
        rm -f "$nodesource_script"
        exit 1
      fi
      $SUDO bash "$nodesource_script"
      rm -f "$nodesource_script"
      $SUDO dnf install -y nodejs
      ;;
    pacman)
      $SUDO pacman -S --noconfirm nodejs npm
      ;;
    zypper)
      nodesource_script=$(mktemp /tmp/kilo-install-nodesource.XXXXXX)
      curl -fsSL -o "$nodesource_script" https://rpm.nodesource.com/setup_lts.x
      if [ ! -s "$nodesource_script" ]; then
        err "Gagal mengunduh NodeSource setup script (file kosong)"
        rm -f "$nodesource_script"
        exit 1
      fi
      if ! head -5 "$nodesource_script" | grep -qi "bash\|nodesource\|nodejs" 2>/dev/null; then
        err "NodeSource setup script tidak valid (header tidak dikenal)"
        rm -f "$nodesource_script"
        exit 1
      fi
      $SUDO bash "$nodesource_script"
      rm -f "$nodesource_script"
      $SUDO zypper install -y nodejs
      ;;
  esac

  ok "Node.js terinstall: $(node --version)"
}

# ============================================================================
# Install Docker
# ============================================================================
install_docker() {
  header "Memeriksa Docker"

  if command -v docker &>/dev/null; then
    ok "Docker sudah terinstall: $(docker --version 2>/dev/null | head -1)"
    return
  fi

  info "Menginstall Docker..."

  case "$PKG_MANAGER" in
    apt)
      $SUDO apt-get update -y
      $SUDO apt-get install -y ca-certificates gnupg
      $SUDO install -m 0755 -d /etc/apt/keyrings

      # Download Docker GPG key to temp file, verify, then install
      local docker_gpg_tmp
      docker_gpg_tmp=$(mktemp /tmp/kilo-install-docker-gpg.XXXXXX)
      curl -fsSL -o "$docker_gpg_tmp" "https://download.docker.com/linux/$DISTRO_ID/gpg"
      if [ ! -s "$docker_gpg_tmp" ]; then
        err "Gagal mengunduh Docker GPG key (file kosong)"
        rm -f "$docker_gpg_tmp"
        exit 1
      fi
      if ! gpg --batch --quiet --import --dry-run "$docker_gpg_tmp" 2>/dev/null; then
        err "Docker GPG key tidak valid"
        rm -f "$docker_gpg_tmp"
        exit 1
      fi
      $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg "$docker_gpg_tmp" 2>/dev/null
      rm -f "$docker_gpg_tmp"

      if [ ! -s /etc/apt/keyrings/docker.gpg ]; then
        err "Docker GPG keyring file kosong setelah import"
        exit 1
      fi
      $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

      local arch
      arch=$(dpkg --print-architecture)

      # Use VERSION_CODENAME from /etc/os-release as primary, fallback to lsb_release
      local os_codename
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_codename="${VERSION_CODENAME:-}"
      fi
      if [ -z "$os_codename" ]; then
        os_codename=$(lsb_release -cs 2>/dev/null || true)
      fi
      if [ -z "$os_codename" ]; then
        warn "Tidak bisa mendeteksi codename OS, menggunakan 'stable' sebagai fallback"
        os_codename="stable"
      fi
      echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO_ID $os_codename stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

      $SUDO apt-get update -y
      $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      ;;
    dnf)
      $SUDO dnf -y install dnf-plugins-core
      $SUDO dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      $SUDO dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      ;;
    pacman)
      $SUDO pacman -S --noconfirm docker docker-compose
      ;;
    zypper)
      $SUDO zypper install -y docker docker-compose
      ;;
  esac

  $SUDO systemctl enable docker 2>/dev/null || true
  $SUDO systemctl start docker 2>/dev/null || true

  ok "Docker terinstall"
}

# ============================================================================
# Add user to docker group
# ============================================================================
setup_docker_group() {
  header "Mengatur Docker group"

  if groups "$USER" 2>/dev/null | grep -q docker; then
    ok "User '$USER' sudah di docker group"
    return
  fi

  $SUDO groupadd docker 2>/dev/null || true
  $SUDO usermod -aG docker "$USER"
  warn "User '$USER' ditambahkan ke docker group."

  # Attempt to activate docker group in current session
  if command -v newgrp &>/dev/null; then
    warn "Menjalankan: newgrp docker (perintah shell, grup aktif di sesi baru)"
  elif command -v sg &>/dev/null; then
    warn "Menjalankan: sg docker -c \"...\" (grup aktif di sesi baru)"
  fi
  $SUDO -u "$USER" sg docker -c "docker ps -q" 2>/dev/null && ok "Docker group aktif di sesi ini" || \
    warn "Anda perlu logout dan login lagi agar Docker bisa dipakai tanpa sudo."
}

# ============================================================================
# Install Kilo CLI
# ============================================================================
install_kilo() {
  header "Memeriksa Kilo CLI"

  if command -v kilo &>/dev/null; then
    ok "Kilo CLI sudah terinstall"
    return
  fi

  info "Menginstall Kilo CLI..."

  local kilo_install_script
  kilo_install_script=$(mktemp /tmp/kilo-install-kilo.XXXXXX)
  curl -fsSL -o "$kilo_install_script" https://kilo.ai/cli/install
  if [ ! -s "$kilo_install_script" ]; then
    err "Gagal mengunduh Kilo CLI installer (file kosong)"
    rm -f "$kilo_install_script"
    exit 1
  fi
  if ! head -5 "$kilo_install_script" | grep -qi "bash\|kilo\|install" 2>/dev/null; then
    err "Kilo CLI installer tidak valid (header tidak dikenal)"
    rm -f "$kilo_install_script"
    exit 1
  fi
  bash "$kilo_install_script"
  rm -f "$kilo_install_script"

  # Ensure kilo is in PATH for this session
  export PATH="$HOME/.local/bin:$HOME/.kilo/bin:$PATH"

  if command -v kilo &>/dev/null; then
    ok "Kilo CLI terinstall"
  else
    warn "Kilo CLI terinstall tapi tidak ditemukan di PATH. Pastikan ~/.local/bin ada di PATH Anda."
  fi

  # Persist Kilo CLI PATH to shell config with duplicate guard
  local path_line="export PATH=\"\$HOME/.local/bin:\$HOME/.kilo/bin:\$PATH\""
  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
      if ! grep -qF 'export PATH="$HOME/.local/bin:$HOME/.kilo/bin:$PATH"' "$rc_file" 2>/dev/null; then
        echo "$path_line" >> "$rc_file"
        ok "Kilo PATH ditambahkan ke $rc_file"
      fi
    fi
  done
}

# ============================================================================
# Model selection
# ============================================================================
select_provider() {
  header "Pilih AI Model Provider"

  echo "Pilih provider yang ingin Anda gunakan:"
  echo ""
  echo "  1) DeepSeek   (deepseek-chat) — https://platform.deepseek.com/ [default]"
  echo "  2) Anthropic  (Claude)          — https://console.anthropic.com/"
  echo "  3) OpenAI     (GPT)             — https://platform.openai.com/api-keys"
  echo "  4) Google     (Gemini)          — https://aistudio.google.com/apikey"
  echo "  5) OpenRouter (Multi-model)     — https://openrouter.ai/keys"
  echo ""

  local choice
  while true; do
    read -rp "Pilihan Anda [1-5]: " choice
    choice="${choice:-1}"
    case "$choice" in
      1)
        PROVIDER_ID="deepseek"
        PROVIDER_NAME="DeepSeek"
        DEFAULT_MODEL="deepseek-chat"
        break
        ;;
      2)
        PROVIDER_ID="anthropic"
        PROVIDER_NAME="Anthropic"
        DEFAULT_MODEL="claude-sonnet-4"
        break
        ;;
      3)
        PROVIDER_ID="openai"
        PROVIDER_NAME="OpenAI"
        DEFAULT_MODEL="gpt-4o"
        break
        ;;
      4)
        PROVIDER_ID="gemini"
        PROVIDER_NAME="Gemini"
        DEFAULT_MODEL="gemini-2.5-flash"
        break
        ;;
      5)
        PROVIDER_ID="openrouter"
        PROVIDER_NAME="OpenRouter"
        DEFAULT_MODEL="anthropic/claude-sonnet-4"
        break
        ;;
      *)
        warn "Pilihan tidak valid. Masukkan angka 1-5."
        ;;
    esac
  done

  echo ""
  info "Provider dipilih: $PROVIDER_NAME"
  info "Model default: $DEFAULT_MODEL"
  echo ""

  if [ "$PROVIDER_ID" = "deepseek" ]; then
    read -rsp "Hubungi tim Anda untuk mendapatkan API key DeepSeek, lalu masukkan di sini: " API_KEY
  else
    read -rsp "Masukkan API Key $PROVIDER_NAME Anda: " API_KEY
  fi

  echo ""
  if [ -z "$API_KEY" ]; then
    err "API Key tidak boleh kosong!"
    exit 1
  fi

  ok "API Key diterima"
}

# ============================================================================
# Validate API key
# ============================================================================
validate_api_key() {
  header "Memvalidasi API Key"

  local max_attempts=3
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    local http_code
    local response

    case "$PROVIDER_ID" in
      deepseek)
        response=$(curl -s -w "\\n%{http_code}" -X POST "https://api.deepseek.com/v1/models" \
          -H "Authorization: Bearer $API_KEY" 2>&1) || true
        ;;
      anthropic)
        response=$(curl -s -w "\\n%{http_code}" "https://api.anthropic.com/v1/models" \
          -H "x-api-key: $API_KEY" \
          -H "anthropic-version: 2023-06-01" 2>&1) || true
        ;;
      openai)
        response=$(curl -s -w "\\n%{http_code}" "https://api.openai.com/v1/models" \
          -H "Authorization: Bearer $API_KEY" 2>&1) || true
        ;;
      gemini)
        response=$(curl -s -w "\\n%{http_code}" "https://generativelanguage.googleapis.com/v1/models?key=$API_KEY" 2>&1) || true
        ;;
      openrouter)
        response=$(curl -s -w "\\n%{http_code}" "https://openrouter.ai/api/v1/models" \
          -H "Authorization: Bearer $API_KEY" 2>&1) || true
        ;;
    esac

    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
      ok "API Key valid"
      return 0
    fi

    err "API Key tidak valid atau tidak berfungsi (HTTP $http_code)."
    echo "$body" | head -3

    if [ $attempt -lt $max_attempts ]; then
      echo ""
      warn "Percobaan $attempt dari $max_attempts gagal."
      read -rp "Masukkan ulang API Key (atau tekan Enter untuk keluar): " new_key
      if [ -z "$new_key" ]; then
        err "Validasi API Key gagal. Keluar."
        exit 1
      fi
      API_KEY="$new_key"
    fi

    attempt=$((attempt + 1))
  done

  err "Gagal memvalidasi API Key setelah $max_attempts percobaan. Keluar."
  exit 1
}

# ============================================================================
# Deploy config files
# ============================================================================
deploy_config() {
  header "Mengkonfigurasi Kilo"

  mkdir -p "$KILO_CONFIG_DIR/agents"
  mkdir -p "$KILO_CONFIG_DIR/commands"
  mkdir -p "$KILO_CONFIG_DIR/skills/project-builder"

  # Download and process kilo.jsonc
  info "Mengunduh konfigurasi..."
  local jsonc_content
  jsonc_content=$(curl -fsSL "$REPO_RAW/config/kilo.jsonc")

  # Replace placeholders
  jsonc_content="${jsonc_content//__MODEL__/$DEFAULT_MODEL}"
  jsonc_content="${jsonc_content//__PROVIDER__/$PROVIDER_ID}"
  jsonc_content="${jsonc_content//__API_KEY__/$API_KEY}"

  echo "$jsonc_content" > "$KILO_CONFIG_DIR/kilo.jsonc"

  # Create MCP-restricted projects directory
  mkdir -p "$HOME/kilo-projects"

  # Download agent
  info "Mengunduh agent assistant..."
  curl -fsSL "$REPO_RAW/config/agents/assistant.md" > "$KILO_CONFIG_DIR/agents/assistant.md"

  # Download commands
  info "Mengunduh commands..."
  curl -fsSL "$REPO_RAW/config/commands/start.md" > "$KILO_CONFIG_DIR/commands/start.md"
  curl -fsSL "$REPO_RAW/config/commands/status.md" > "$KILO_CONFIG_DIR/commands/status.md"

  # Download skills
  info "Mengunduh skills..."
  curl -fsSL "$REPO_RAW/config/skills/project-builder/SKILL.md" > "$KILO_CONFIG_DIR/skills/project-builder/SKILL.md"

  ok "Konfigurasi terdeploy"
}

# ============================================================================
# Set permissions
# ============================================================================
set_permissions() {
  header "Mengatur permissions"

  chown -R "$USER:$USER" "$KILO_CONFIG_DIR" 2>/dev/null || true
  find "$KILO_CONFIG_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
  # sensitive config (contains API key) → owner-only
  chmod 600 "$KILO_CONFIG_DIR/kilo.jsonc" 2>/dev/null || true
  find "$KILO_CONFIG_DIR" -type f -not -name 'kilo.jsonc' -exec chmod 644 {} \; 2>/dev/null || true

  ok "Permissions teratur"
}

# ============================================================================
# Verify installation
# ============================================================================
verify_install() {
  header "Verifikasi instalasi"

  local all_ok=true

  if command -v node &>/dev/null; then
    ok "Node.js: $(node --version)"
  else
    err "Node.js tidak ditemukan"
    all_ok=false
  fi

  if command -v npm &>/dev/null; then
    ok "npm: $(npm --version)"
  else
    err "npm tidak ditemukan"
    all_ok=false
  fi

  if command -v docker &>/dev/null; then
    ok "Docker: $(docker --version 2>/dev/null | head -1)"
  else
    warn "Docker tidak ditemukan (opsional tapi direkomendasikan)"
  fi

  if command -v kilo &>/dev/null; then
    ok "Kilo CLI: terinstall"
  else
    warn "Kilo CLI tidak ditemukan di PATH"
  fi

  if [ -f "$KILO_CONFIG_DIR/kilo.jsonc" ]; then
    ok "Konfigurasi: $KILO_CONFIG_DIR/kilo.jsonc"
  else
    err "Konfigurasi tidak ditemukan"
  fi
}

# ============================================================================
# Cleanup
# ============================================================================
cleanup() {
  header "Pembersihan"

  info "Menghapus file sementara..."
  rm -f /tmp/kilo-install-* 2>/dev/null || true
  ok "Selesai"
}

# ============================================================================
# Main
# ============================================================================
main() {
  header "Selamat datang di Kilo CLI Installer"

  parse_args "$@"

  setup_sudo
  detect_distro
  install_prerequisites
  install_nodejs
  install_docker
  setup_docker_group
  install_kilo

  if [ "$NON_INTERACTIVE" = false ]; then
    select_provider
    validate_api_key
  else
    info "Non-interactive mode: menggunakan provider $PROVIDER_NAME dengan model $DEFAULT_MODEL"
  fi

  deploy_config
  set_permissions
  verify_install
  cleanup

  echo ""
  header "Instalasi selesai!"
  echo ""
  info "Untuk memulai, jalankan: kilo"
  echo ""
}

main "$@"
