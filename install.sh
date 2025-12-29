#!/bin/bash
# ==============================================================================
# YUZU'S DOTFILES - BOOTSTRAP SCRIPT
# One-command setup for fresh Arch/WSL installations
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██╗   ██╗██╗   ██╗███████╗██╗   ██╗                        ║
║   ╚██╗ ██╔╝██║   ██║╚══███╔╝██║   ██║                        ║
║    ╚████╔╝ ██║   ██║  ███╔╝ ██║   ██║                        ║
║     ╚██╔╝  ██║   ██║ ███╔╝  ██║   ██║                        ║
║      ██║   ╚██████╔╝███████╗╚██████╔╝                        ║
║      ╚═╝    ╚═════╝ ╚══════╝ ╚═════╝                         ║
║                                                               ║
║              🏠 Dotfiles Bootstrap Script                     ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root - will auto-create user
if [ "$(id -u)" -eq 0 ]; then
    log_warn "Running as root detected - user will be created automatically"
fi

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        log_info "Detected OS: $OS"
    else
        log_error "Cannot detect OS"
        exit 1
    fi
}

# Detect WSL
detect_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        log_info "Running on WSL"
    else
        IS_WSL=false
    fi
}

# Install chezmoi
install_chezmoi() {
    if command -v chezmoi &>/dev/null; then
        log_success "chezmoi already installed: $(chezmoi --version)"
        return 0
    fi

    log_info "Installing chezmoi..."
    
    case "$OS" in
        arch|endeavouros|manjaro)
            if command -v paru &>/dev/null; then
                paru -S --needed --noconfirm chezmoi
            elif command -v yay &>/dev/null; then
                yay -S --needed --noconfirm chezmoi
            else
                sudo pacman -S --needed --noconfirm chezmoi
            fi
            ;;
        ubuntu|debian|pop)
            sudo apt-get update
            sudo apt-get install -y curl
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        fedora)
            sudo dnf install -y chezmoi
            ;;
        *)
            # Universal install
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
            export PATH="$HOME/.local/bin:$PATH"
            ;;
    esac
    
    log_success "chezmoi installed successfully"
}

# Initialize dotfiles
init_dotfiles() {
    local GITHUB_USER="${1:-Yuzu02}"
    local REPO_URL="https://github.com/${GITHUB_USER}/dotfiles.git"
    
    log_info "Initializing dotfiles from $REPO_URL"
    
    if [ -d "$HOME/.local/share/chezmoi" ] && [ -n "$(ls -A $HOME/.local/share/chezmoi 2>/dev/null)" ]; then
        log_warn "Existing chezmoi directory found"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing configuration"
            return 0
        fi
        rm -rf "$HOME/.local/share/chezmoi"
    fi
    
    chezmoi init "$REPO_URL"
    log_success "Dotfiles initialized"
}

# Apply dotfiles
apply_dotfiles() {
    log_info "Applying dotfiles..."
    chezmoi apply -v
    log_success "Dotfiles applied successfully!"
}

# Post-install setup
post_install() {
    log_info "Running post-install setup..."
    
    # Set zsh as default shell
    if command -v zsh &>/dev/null; then
        if [ "$SHELL" != "$(which zsh)" ]; then
            log_info "Setting zsh as default shell..."
            chsh -s "$(which zsh)" || log_warn "Could not change default shell"
        fi
    fi
    
    log_success "Post-install complete!"
}

# Main
main() {
    local GITHUB_USER="${1:-Yuzu02}"
    
    echo -e "${CYAN}Starting bootstrap process...${NC}\n"
    
    detect_os
    detect_wsl
    install_chezmoi
    init_dotfiles "$GITHUB_USER"
    apply_dotfiles
    post_install
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}║   ✅ Bootstrap Complete!                                      ║${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}║   Please restart your terminal or run:                        ║${NC}"
    echo -e "${GREEN}║   ${YELLOW}exec zsh${GREEN}                                                  ║${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Run
main "$@"
