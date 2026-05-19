#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kilo End-User Installer
# One-command setup for Kilo CLI with pre-configured Indonesian AI agent
# Usage: curl -fsSL https://raw.githubusercontent.com/u-r-ai/kilo-end-user/main/install.sh | bash
# ============================================================================

REPO_RAW="https://raw.githubusercontent.com/u-r-ai/kilo-end-user/main"
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

  # Keep sudo alive in background
  while true; do sudo -n true; sleep 60; kill -0 "$SCRIPT_PID" 2>/dev/null || exit; done 2>/dev/null &
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

  case "$PKG_MANAGER" in
    apt)
      curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO bash -
      $SUDO apt-get install -y nodejs
      ;;
    dnf)
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | $SUDO bash -
      $SUDO dnf install -y nodejs
      ;;
    pacman)
      $SUDO pacman -S --noconfirm nodejs npm
      ;;
    zypper)
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | $SUDO bash -
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
      curl -fsSL https://download.docker.com/linux/$DISTRO_ID/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
      $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

      local arch
      arch=$(dpkg --print-architecture)
      echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO_ID $(lsb_release -cs 2>/dev/null || echo stable) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

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
  curl -fsSL https://kilo.ai/cli/install | bash

  # Ensure kilo is in PATH for this session
  export PATH="$HOME/.local/bin:$HOME/.kilo/bin:$PATH"

  if command -v kilo &>/dev/null; then
    ok "Kilo CLI terinstall"
  else
    warn "Kilo CLI terinstall tapi tidak ditemukan di PATH. Pastikan ~/.local/bin ada di PATH Anda."
  fi
}

# ============================================================================
# Model selection
# ============================================================================
select_provider() {
  header "Pilih AI Model Provider"

  echo "Pilih provider yang ingin Anda gunakan:"
  echo ""
  echo "  1) DeepSeek   (DeepSeek V4 Pro) — https://platform.deepseek.com/ [default]"
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
        DEFAULT_MODEL="deepseek-v4-pro"
        break
        ;;
      2)
        PROVIDER_ID="anthropic"
        PROVIDER_NAME="Anthropic"
        DEFAULT_MODEL="claude-sonnet-4-20250514"
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
        DEFAULT_MODEL="anthropic/claude-sonnet-4-20250514"
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
    read -rp "Hubungi tim Anda untuk mendapatkan API key DeepSeek, lalu masukkan di sini: " API_KEY
  else
    read -rp "Masukkan API Key $PROVIDER_NAME Anda: " API_KEY
  fi

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
        response=$(curl -s -w "\n%{http_code}" -X POST "https://api.deepseek.com/v1/models" \
          -H "Authorization: Bearer $API_KEY" 2>&1) || true
        ;;
      anthropic)
        response=$(curl -s -w "\n%{http_code}" "https://api.anthropic.com/v1/models" \
          -H "x-api-key: $API_KEY" \
          -H "anthropic-version: 2023-06-01" 2>&1) || true
        ;;
      openai)
        response=$(curl -s -w "\n%{http_code}" "https://api.openai.com/v1/models" \
          -H "Authorization: Bearer $API_KEY" 2>&1) || true
        ;;
      gemini)
        response=$(curl -s -w "\n%{http_code}" "https://generativelanguage.googleapis.com/v1/models?key=$API_KEY" 2>&1) || true
        ;;
      openrouter)
        response=$(curl -s -w "\n%{http_code}" "https://openrouter.ai/api/v1/models" \
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
  find "$KILO_CONFIG_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true

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
    all_ok=false
  fi

  if [ -f "$KILO_CONFIG_DIR/agents/assistant.md" ]; then
    ok "Agent: assistant"
  else
    err "Agent assistant tidak ditemukan"
    all_ok=false
  fi

  if $all_ok; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Print success
# ============================================================================
print_success() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  Instalasi Selesai!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "  Provider: $PROVIDER_NAME"
  echo "  Model:    $DEFAULT_MODEL"
  echo "  Config:   $KILO_CONFIG_DIR/"
  echo ""
  echo "  Cara menjalankan:"
  echo ""
  echo "    1. Buka terminal baru (atau logout & login jika Docker baru diinstall)"
  echo "    2. Jalankan: kilo"
  echo "    3. Ketik pesan Anda, contoh:"
  echo ""
  echo '       "Saya mau bikin aplikasi laundry"'
  echo '       "Buatkan landing page untuk bisnis saya"'
  echo '       "Buat automation untuk kirim invoice"'
  echo ""
  echo "  Commands yang tersedia:"
  echo "    /start   — Mulai project baru"
  echo "    /status  — Cek status sistem"
  echo ""
  echo -e "${CYAN}  Dokumentasi: https://github.com/u-r-ai/kilo-end-user${NC}"
  echo ""
}

# ============================================================================
# Main
# ============================================================================
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║       Kilo End-User — AI Software Builder           ║${NC}"
  echo -e "${CYAN}║       Installer untuk Linux                         ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""

  setup_sudo
  detect_distro
  install_prerequisites
  install_nodejs
  install_docker
  setup_docker_group
  install_kilo
  select_provider
  validate_api_key
  deploy_config
  set_permissions

  if verify_install; then
    print_success
  else
    err "Instalasi selesai dengan beberapa masalah. Periksa pesan di atas."
    exit 1
  fi
}

main "$@"
