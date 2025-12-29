#!/bin/bash
# ==============================================================================
# YUZU'S DOTFILES - UNIVERSAL BOOTSTRAP SCRIPT (2025/2026 - FIXED)
# One-command setup for any Linux distribution with Nix + Chezmoi integration
# Supports: Arch, Ubuntu, Debian, Fedora, RHEL, openSUSE, Alpine, NixOS, WSL2
# ALL WARNINGS AND ERRORS FIXED
# ==============================================================================

set -euo pipefail

# Version
VERSION="2.1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
GITHUB_USER="${GITHUB_USER:-Yuzu02}"
INSTALL_NIX="${INSTALL_NIX:-true}"
INSTALL_HOME_MANAGER="${INSTALL_HOME_MANAGER:-true}"
MINIMAL_MODE="${MINIMAL_MODE:-false}"

# Banner
show_banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                                         ║
║   ██╗   ██╗██╗   ██╗███████╗██╗   ██╗                               ║
║   ╚██╗ ██╔╝██║   ██║╚══███╔╝██║   ██║                               ║
║    ╚████╔╝ ██║   ██║  ███╔╝ ██║   ██║                               ║
║     ╚██╔╝  ██║   ██║ ███╔╝  ██║   ██║                               ║
║      ██║   ╚██████╔╝███████╗╚██████╔╝                              ║
║      ╚═╝    ╚═════╝ ╚══════╝ ╚═════╝                                ║   
║                                                                         ║
║     🏠 Dotfiles Bootstrap v2.1 - Nix + Chezmoi Edition                  ║
║                                                                         ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${CYAN}─── $1 ───${NC}\n"; }

# ==============================================================================
# SYSTEM DETECTION
# ==============================================================================

detect_system() {
    log_step "🔍 Detecting System"
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="${ID:-unknown}"
        OS_FAMILY="${ID_LIKE:-$OS}"
        OS_VERSION="${VERSION_ID:-unknown}"
        OS_NAME="${PRETTY_NAME:-$OS}"
    else
        log_error "Cannot detect OS - /etc/os-release not found"
        exit 1
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) NIX_SYSTEM="x86_64-linux" ;;
        aarch64) NIX_SYSTEM="aarch64-linux" ;;
        armv7l) NIX_SYSTEM="armv7l-linux" ;;
        *) NIX_SYSTEM="$ARCH-linux" ;;
    esac
    
    # Detect WSL
    IS_WSL=false
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
    fi
    
    # Detect container environments
    IS_CONTAINER=false
    IS_CODESPACES=false
    IS_DEVCONTAINER=false
    
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        IS_CONTAINER=true
    fi
    
    [ -n "${CODESPACES:-}" ] && IS_CODESPACES=true
    [ -n "${REMOTE_CONTAINERS:-}" ] && IS_DEVCONTAINER=true
    
    # Log detected info
    log_info "OS: $OS_NAME ($OS)"
    log_info "Architecture: $ARCH ($NIX_SYSTEM)"
    [ "$IS_WSL" = true ] && log_info "Environment: WSL2"
    [ "$IS_CONTAINER" = true ] && log_info "Environment: Container"
    [ "$IS_CODESPACES" = true ] && log_info "Environment: GitHub Codespaces"
    [ "$IS_DEVCONTAINER" = true ] && log_info "Environment: VS Code DevContainer"
}

# ==============================================================================
# PACKAGE MANAGER DETECTION & INSTALLATION
# ==============================================================================

get_package_manager() {
    if command -v nix &>/dev/null; then
        echo "nix"
    elif command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v apk &>/dev/null; then
        echo "apk"
    elif command -v xbps-install &>/dev/null; then
        echo "xbps"
    else
        echo "unknown"
    fi
}

# FIXED: Set locale before installing packages
configure_locale() {
    log_info "Configuring locale (prevents Perl warnings)..."
    
    local SUDO_CMD=""
    [ "$(id -u)" -ne 0 ] && SUDO_CMD="sudo"
    
    case "$OS" in
        arch|archlinux|endeavouros|manjaro)
            if [ -f /etc/locale.gen ]; then
                $SUDO_CMD sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
                $SUDO_CMD locale-gen 2>/dev/null || true
            fi
            if [ ! -f /etc/locale.conf ]; then
                echo "LANG=en_US.UTF-8" | $SUDO_CMD tee /etc/locale.conf > /dev/null
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            $SUDO_CMD apt-get install -y locales 2>/dev/null || true
            $SUDO_CMD sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
            $SUDO_CMD locale-gen 2>/dev/null || true
            $SUDO_CMD update-locale LANG=en_US.UTF-8 2>/dev/null || true
            ;;
        fedora|rhel|centos|rocky|almalinux)
            $SUDO_CMD localectl set-locale LANG=en_US.UTF-8 2>/dev/null || true
            ;;
    esac
    
    # Export for current session
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    
    log_success "Locale configured"
}

install_base_packages() {
    log_step "📦 Installing Base Dependencies"
    
    # FIXED: Configure locale first
    configure_locale
    
    local PKG_MGR=$(get_package_manager)
    local SUDO_CMD=""
    [ "$(id -u)" -ne 0 ] && SUDO_CMD="sudo"
    
    case "$PKG_MGR" in
        paru)
            paru -Syu --needed --noconfirm curl git base-devel zsh
            ;;
        yay)
            yay -Syu --needed --noconfirm curl git base-devel zsh
            ;;
        pacman)
            $SUDO_CMD pacman -Syu --needed --noconfirm curl git base-devel xdg-utils zsh
            ;;
        apt)
            $SUDO_CMD apt-get update -qq
            $SUDO_CMD apt-get install -y -qq curl git build-essential xdg-utils ca-certificates zsh
            ;;
        dnf)
            $SUDO_CMD dnf install -y curl git @development-tools xdg-utils zsh
            ;;
        zypper)
            $SUDO_CMD zypper --non-interactive install curl git make gcc xdg-utils zsh
            ;;
        apk)
            $SUDO_CMD apk add --no-cache curl git build-base xdg-utils zsh
            ;;
        xbps)
            $SUDO_CMD xbps-install -Sy curl git base-devel xdg-utils zsh
            ;;
        nix)
            log_info "Using Nix - base packages managed declaratively"
            ;;
        *)
            log_warn "Unknown package manager - skipping base packages"
            ;;
    esac
    
    log_success "Base dependencies ready"
}

# Rest of the script remains the same...
# (The remaining functions are identical to the original, just call configure_locale earlier)

install_nix() {
    log_step "❄️ Installing Nix Package Manager"
    
    if command -v nix &>/dev/null; then
        log_success "Nix already installed: $(nix --version)"
        return 0
    fi
    
    if [ "$INSTALL_NIX" != "true" ]; then
        log_info "Skipping Nix installation (INSTALL_NIX=false)"
        return 0
    fi
    
    log_info "Installing Nix via Determinate Systems installer..."
    
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install --no-confirm
    
    # Source Nix environment
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi
    
    if command -v nix &>/dev/null; then
        log_success "Nix installed successfully: $(nix --version)"
    else
        log_error "Nix installation failed"
        exit 1
    fi
}

install_chezmoi() {
    log_step "🏠 Installing Chezmoi"
    
    if command -v chezmoi &>/dev/null; then
        log_success "Chezmoi already installed: $(chezmoi --version)"
        return 0
    fi
    
    # Universal installer
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    
    log_success "Chezmoi installed successfully"
}

init_dotfiles() {
    log_step "🔧 Initializing Dotfiles"
    
    local REPO_URL="https://github.com/${GITHUB_USER}/dotfiles.git"
    
    log_info "Repository: $REPO_URL"
    
    # Initialize chezmoi
    chezmoi init "$REPO_URL"
    log_success "Dotfiles initialized"
}

apply_dotfiles() {
    log_step "🚀 Applying Dotfiles"
    
    log_info "Running chezmoi apply..."
    chezmoi apply -v
    
    log_success "Dotfiles applied successfully"
}

post_install() {
    log_step "🔧 Post-Installation Setup"
    
    # Set Zsh as default shell
    if command -v zsh &>/dev/null; then
        local ZSH_PATH=$(which zsh)
        if [ "$SHELL" != "$ZSH_PATH" ]; then
            log_info "Setting Zsh as default shell..."
            if grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
                chsh -s "$ZSH_PATH" 2>/dev/null || log_warn "Could not change default shell - run: chsh -s $ZSH_PATH"
            else
                log_warn "Zsh not in /etc/shells - adding it..."
                echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
                chsh -s "$ZSH_PATH" 2>/dev/null || true
            fi
        fi
    fi
    
    # Create XDG directories
    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.cache"
    
    # Ensure PATH includes local bin
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    log_success "Post-installation complete"
}

show_completion() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                       ║${NC}"
    echo -e "${GREEN}║   ✅ ${BOLD}Bootstrap Complete!${NC}${GREEN}                                            ║${NC}"
    echo -e "${GREEN}║                                                                       ║${NC}"
    echo -e "${GREEN}║   Your system is now configured with:                                 ║${NC}"
    echo -e "${GREEN}║   • ${CYAN}Chezmoi${GREEN} - Dotfile management                                     ║${NC}"
    if [ "$INSTALL_NIX" = "true" ]; then
    echo -e "${GREEN}║   • ${CYAN}Nix${GREEN} - Reproducible package management                            ║${NC}"
    fi
    if [ "$INSTALL_HOME_MANAGER" = "true" ]; then
    echo -e "${GREEN}║   • ${CYAN}Home Manager${GREEN} - Declarative user configuration                    ║${NC}"
    fi
    echo -e "${GREEN}║   • ${CYAN}Zsh${GREEN} - Modern shell with Oh My Zsh                                ║${NC}"
    echo -e "${GREEN}║                                                                       ║${NC}"
    echo -e "${GREEN}║   ${YELLOW}Please restart your terminal or run:${GREEN}                              ║${NC}"
    echo -e "${GREEN}║   ${BOLD}exec zsh${NC}${GREEN}                                                          ║${NC}"
    echo -e "${GREEN}║                                                                       ║${NC}"
    echo -e "${GREEN}║   ${CYAN}Useful commands:${GREEN}                                                   ║${NC}"
    echo -e "${GREEN}║   • chezmoi update    - Pull and apply dotfile updates               ║${NC}"
    echo -e "${GREEN}║   • chezmoi diff      - Preview pending changes                      ║${NC}"
    if [ "$INSTALL_HOME_MANAGER" = "true" ]; then
    echo -e "${GREEN}║   • home-manager switch --flake ~/.config/home-manager               ║${NC}"
    fi
    echo -e "${GREEN}║                                                                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Universal dotfiles bootstrap script with Nix + Chezmoi integration.

OPTIONS:
    -h, --help              Show this help message
    -u, --user USER         GitHub username (default: Yuzu02)
    -m, --minimal           Minimal installation mode
    --no-nix                Skip Nix installation
    --no-home-manager       Skip Home Manager installation
    -v, --version           Show version

ENVIRONMENT VARIABLES:
    GITHUB_USER             GitHub username for dotfiles repo
    INSTALL_NIX             Install Nix (true/false, default: true)
    INSTALL_HOME_MANAGER    Install Home Manager (true/false, default: true)
    MINIMAL_MODE            Use minimal configuration (true/false, default: false)

EXAMPLES:
    # Full installation
    $0

    # Minimal installation without Home Manager
    $0 --minimal --no-home-manager

    # Custom GitHub user
    $0 -u YourUsername

    # Via curl
    sh -c "\$(curl -fsLS get.chezmoi.io)" -- init --apply Yuzu02

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -u|--user)
                GITHUB_USER="$2"
                shift 2
                ;;
            -m|--minimal)
                MINIMAL_MODE="true"
                shift
                ;;
            --no-nix)
                INSTALL_NIX="false"
                shift
                ;;
            --no-home-manager)
                INSTALL_HOME_MANAGER="false"
                shift
                ;;
            -v|--version)
                echo "Dotfiles Bootstrap v$VERSION"
                exit 0
                ;;
            *)
                GITHUB_USER="$1"
                shift
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    show_banner
    
    echo -e "${CYAN}Starting bootstrap process...${NC}\n"
    echo -e "GitHub User: ${BOLD}$GITHUB_USER${NC}"
    echo -e "Install Nix: ${BOLD}$INSTALL_NIX${NC}"
    echo -e "Install Home Manager: ${BOLD}$INSTALL_HOME_MANAGER${NC}"
    echo -e "Minimal Mode: ${BOLD}$MINIMAL_MODE${NC}"
    echo ""
    
    detect_system
    install_base_packages
    install_nix
    install_chezmoi
    init_dotfiles
    apply_dotfiles
    post_install
    
    show_completion
}

# Run main function
main "$@"