#!/usr/bin/env bash
#
# install.sh — Automated, Idempotent Installer for QuickShell Top Notch on Arch Linux
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   -y, --yes          Non-interactive mode; auto-confirm all prompts
#   --dry-run          Simulate installation without making system or filesystem changes
#   --link             Symlink repository to ~/.config/quickshell (default when cloned outside)
#   --copy             Copy repository files to ~/.config/quickshell instead of symlinking
#   --no-deps          Skip package dependency checks and installation
#   --no-fonts         Skip font installation and cache update
#   --hyprland         Automatically append launch & persistence lines to Hyprland config
#   --force            Bypass non-Arch Linux OS check warning
#   -h, --help         Show this help message
#

set -euo pipefail

# Preserve original command line arguments before parsing
ORIG_ARGS=("$@")

# ==============================================================================
# Styling and Logging Helpers
# ==============================================================================

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"
    C_RED="\033[31m"
    C_GREEN="\033[32m"
    C_YELLOW="\033[33m"
    C_BLUE="\033[34m"
    C_MAGENTA="\033[35m"
    C_CYAN="\033[36m"
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_MAGENTA=""
    C_CYAN=""
fi

log_info()    { echo -e "${C_BLUE}ℹ${C_RESET} $*"; }
log_step()    { echo -e "${C_CYAN}${C_BOLD}➜${C_RESET} ${C_BOLD}$*${C_RESET}"; }
log_success() { echo -e "${C_GREEN}✔${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}▲ WARNING:${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}✖ ERROR:${C_RESET} $*" >&2; }
log_dry()     { echo -e "${C_MAGENTA}[DRY-RUN]${C_RESET} $*"; }

# ==============================================================================
# Defaults & Arguments Parsing
# ==============================================================================

NON_INTERACTIVE=false
DRY_RUN=false
INSTALL_MODE="symlink"
SKIP_DEPS=false
SKIP_FONTS=false
AUTO_HYPRLAND=false
FORCE_OS=false

show_help() {
    echo -e "${C_BOLD}QuickShell Top Notch — Arch Linux Installer${C_RESET}

${C_BOLD}USAGE:${C_RESET}
    ./install.sh [OPTIONS]

${C_BOLD}OPTIONS:${C_RESET}
    -y, --yes          Non-interactive mode (auto-confirm prompts with defaults)
    --dry-run          Simulate installation without making system or filesystem changes
    --link             Symlink repo into ~/.config/quickshell (default)
    --copy             Copy files into ~/.config/quickshell instead of symlinking
    --no-deps          Skip dependency checking and package installation
    --no-fonts         Skip SF Pro / SF Mono font installation & fc-cache
    --hyprland         Automatically append startup & persistence imports to Hyprland config
    --force            Bypass OS verification checks
    -h, --help         Show this help message and exit

${C_BOLD}EXAMPLES:${C_RESET}
    # Interactive installation (recommended):
    ./install.sh

    # Fully unattended installation:
    ./install.sh -y --hyprland

    # Dry-run inspection:
    ./install.sh --dry-run"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)
            NON_INTERACTIVE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --link)
            INSTALL_MODE="symlink"
            ;;
        --copy)
            INSTALL_MODE="copy"
            ;;
        --no-deps)
            SKIP_DEPS=true
            ;;
        --no-fonts)
            SKIP_FONTS=true
            ;;
        --hyprland)
            AUTO_HYPRLAND=true
            ;;
        --force)
            FORCE_OS=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: '$1'"
            echo "Run './install.sh --help' for usage."
            exit 1
            ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
REPO_DIR="$SCRIPT_DIR"
USER_CONFIG_DIR="${HOME}/.config/quickshell"
USER_FONTS_DIR="${HOME}/.local/share/fonts"
USER_BIN_DIR="${HOME}/.local/bin"

# Support direct curl | bash pipe execution
if [ -z "$REPO_DIR" ] || [ ! -f "${REPO_DIR}/shell.qml" ]; then
    log_info "Detected standalone script execution. Initializing quickshell-notch repository..."
    if [ "$DRY_RUN" = true ]; then
        log_dry "Standalone execution detected. Would clone YogeshKumar14/quickshell-notch into ~/.config/quickshell and run installer with flags: ${ORIG_ARGS[*]}"
        REPO_DIR="$USER_CONFIG_DIR"
    elif [ -d "$USER_CONFIG_DIR" ] && [ -f "$USER_CONFIG_DIR/shell.qml" ]; then
        log_info "Found existing repository at $USER_CONFIG_DIR. Invoking installer..."
        exec bash "$USER_CONFIG_DIR/install.sh" "${ORIG_ARGS[@]}"
    else
        mkdir -p "${HOME}/.config"
        log_info "Cloning YogeshKumar14/quickshell-notch into ~/.config/quickshell..."
        git clone https://github.com/YogeshKumar14/quickshell-notch.git "$USER_CONFIG_DIR"
        exec bash "$USER_CONFIG_DIR/install.sh" "${ORIG_ARGS[@]}"
    fi
fi

prompt_confirm() {
    local message="$1"
    local default="${2:-Y}" # Y or N

    if [ "$DRY_RUN" = true ] || [ "$NON_INTERACTIVE" = true ]; then
        if [ "$default" = "Y" ] || [ "$default" = "y" ]; then
            return 0
        else
            return 1
        fi
    fi

    local prompt_suffix="[Y/n]"
    [ "$default" = "N" ] && prompt_suffix="[y/N]"

    read -r -p "$(echo -e "${C_BOLD}${message}${C_RESET} ${prompt_suffix} ")" response || return 1
    response="${response:-$default}"
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ==============================================================================
# Banner
# ==============================================================================

echo -e "${C_CYAN}${C_BOLD}"
cat <<'EOF'
  ___        _      _     ____  _          _ _ 
 / _ \ _   _(_) ___| | __/ ___|| |__   ___| | |
| | | | | | | |/ __| |/ /\___ \| '_ \ / _ \ | |
| |_| | |_| | | (__|   <  ___) | | | |  __/ | |
 \__\_\\__,_|_|\___|_|\_\|____/|_| |_|\___|_|_|
           T O P   N O T C H   M O R P H
EOF
echo -e "${C_RESET}"
echo -e "${C_DIM}Dynamic Status Bar & Control Center for Hyprland${C_RESET}"
echo -e "${C_DIM}Target: Arch Linux & Arch-based distributions${C_RESET}\n"

if [ "$DRY_RUN" = true ]; then
    log_dry "Dry-run mode active. No files or system configurations will be modified."
    echo ""
fi

# ==============================================================================
# Step 1: Pre-flight Checks (Root & OS Detection)
# ==============================================================================

log_step "[1/6] Running pre-flight system checks..."

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    log_error "Please do NOT run this installer directly with sudo or as root."
    echo "The script must run as your normal user. It will invoke sudo or your AUR helper when needed."
    exit 1
fi

IS_ARCH=false
if [ -f /etc/arch-release ]; then
    IS_ARCH=true
elif [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" =~ ^(arch|cachyos|endeavouros|manjaro|artix|garuda)$ ]] || [[ "${ID_LIKE:-}" =~ arch ]]; then
        IS_ARCH=true
    fi
fi

if [ "$IS_ARCH" = false ] && [ "$FORCE_OS" = false ]; then
    log_warn "This system does not appear to be Arch Linux or an Arch derivative."
    if ! prompt_confirm "Would you like to proceed anyway?" "N"; then
        log_info "Installation aborted."
        exit 0
    fi
else
    log_success "Arch Linux environment verified."
fi

# ==============================================================================
# Step 2: Dependencies Check & Installation
# ==============================================================================

log_step "[2/6] Inspecting system dependencies..."

if [ "$SKIP_DEPS" = true ]; then
    log_info "Skipping dependency installation (--no-deps specified)."
else
    CORE_PACKAGES=(
        "quickshell"
        "hyprland"
        "cava"
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
        "matugen"
        "awww"
        "playerctl"
        "socat"
        "grim"
        "ffmpeg"
        "libnotify"
        "brightnessctl"
        "networkmanager"
        "bluez"
        "bluez-utils"
        "swaync"
        "python"
        "python-pillow"
        "python-dbus"
        "python-gobject"
        "python-requests"
        "qt6-5compat"
        "qt6-svg"
        "fontconfig"
        "ttf-jetbrains-mono-nerd"
    )

    MISSING_PACKAGES=()
    INSTALLED_COUNT=0

    # Detect AUR helpers
    AUR_HELPER=""
    if command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    elif command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    fi

    for pkg in "${CORE_PACKAGES[@]}"; do
        # Special check: quickshell or quickshell-git
        if [ "$pkg" = "quickshell" ]; then
            if pacman -Q quickshell >/dev/null 2>&1 || pacman -Q quickshell-git >/dev/null 2>&1; then
                INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
                continue
            fi
        # Special check: matugen or wallust
        elif [ "$pkg" = "matugen" ]; then
            if pacman -Q matugen >/dev/null 2>&1 || pacman -Q wallust >/dev/null 2>&1 || pacman -Q wallust-git >/dev/null 2>&1 || pacman -Q wallust-bin >/dev/null 2>&1; then
                INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
                continue
            fi
        # Special check: awww or swww
        elif [ "$pkg" = "awww" ]; then
            if pacman -Q awww >/dev/null 2>&1 || pacman -Q swww >/dev/null 2>&1; then
                INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
                continue
            fi
        elif pacman -Q "$pkg" >/dev/null 2>&1; then
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
            continue
        fi
        MISSING_PACKAGES+=("$pkg")
    done

    log_info "Found $INSTALLED_COUNT/${#CORE_PACKAGES[@]} dependencies already satisfied."

    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo -e "\n${C_YELLOW}Missing dependencies to install:${C_RESET}"
        for mpkg in "${MISSING_PACKAGES[@]}"; do
            echo -e "  - ${C_BOLD}${mpkg}${C_RESET}"
        done
        echo ""

        if [ -n "$AUR_HELPER" ]; then
            log_info "Detected AUR helper: ${C_BOLD}${AUR_HELPER}${C_RESET}"
            if [ "$DRY_RUN" = true ]; then
                log_dry "Would install missing packages via: $AUR_HELPER -S --needed ${MISSING_PACKAGES[*]}"
            else
                if prompt_confirm "Install missing packages now with ${AUR_HELPER}?" "Y"; then
                    log_info "Running ${AUR_HELPER}..."
                    HELPER_FLAGS=("--needed")
                    if [ "$NON_INTERACTIVE" = true ]; then
                        HELPER_FLAGS+=("--noconfirm")
                    fi
                    "$AUR_HELPER" -S "${HELPER_FLAGS[@]}" "${MISSING_PACKAGES[@]}"
                    log_success "Dependencies installed successfully via ${AUR_HELPER}."
                else
                    log_warn "Proceeding without installing missing dependencies. Some features may not work."
                fi
            fi
        else
            # No AUR helper: separate official repository packages from AUR packages
            OFFICIAL_PKGS=()
            AUR_PKGS=()
            for mpkg in "${MISSING_PACKAGES[@]}"; do
                if pacman -Si "$mpkg" >/dev/null 2>&1; then
                    OFFICIAL_PKGS+=("$mpkg")
                else
                    AUR_PKGS+=("$mpkg")
                fi
            done

            if [ ${#OFFICIAL_PKGS[@]} -gt 0 ]; then
                if [ "$DRY_RUN" = true ]; then
                    log_dry "Would install official packages via: sudo pacman -S --needed ${OFFICIAL_PKGS[*]}"
                else
                    if prompt_confirm "Install official packages now with pacman?" "Y"; then
                        log_info "Running pacman..."
                        PACMAN_FLAGS=("--needed")
                        if [ "$NON_INTERACTIVE" = true ]; then
                            PACMAN_FLAGS+=("--noconfirm")
                        fi
                        sudo pacman -S "${PACMAN_FLAGS[@]}" "${OFFICIAL_PKGS[@]}"
                        log_success "Official dependencies installed successfully."
                    else
                        log_warn "Skipped official package installation."
                    fi
                fi
            fi

            if [ ${#AUR_PKGS[@]} -gt 0 ]; then
                if [ "$DRY_RUN" = true ]; then
                    log_dry "Would build and install AUR packages via manual makepkg -si: ${AUR_PKGS[*]}"
                else
                    log_warn "The following packages require building from AUR (no yay/paru helper detected):"
                    for apkg in "${AUR_PKGS[@]}"; do
                        echo -e "  - ${C_BOLD}${apkg}${C_RESET}"
                    done

                    if prompt_confirm "Build and install these AUR packages using makepkg -si?" "Y"; then
                        # Ensure base-devel and git are available
                        if ! pacman -Q base-devel >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
                            log_info "Installing base-devel and git for makepkg..."
                            sudo pacman -S --needed --noconfirm base-devel git
                        fi

                        for apkg in "${AUR_PKGS[@]}"; do
                            TMP_BUILD_DIR="/tmp/aur-${apkg}-$$"
                            log_info "Cloning AUR package: $apkg..."
                            rm -rf "$TMP_BUILD_DIR"
                            git clone "https://aur.archlinux.org/${apkg}.git" "$TMP_BUILD_DIR"
                            (
                                cd "$TMP_BUILD_DIR"
                                MAKEPKG_FLAGS=("-si" "--needed")
                                if [ "$NON_INTERACTIVE" = true ]; then
                                    MAKEPKG_FLAGS+=("--noconfirm")
                                fi
                                makepkg "${MAKEPKG_FLAGS[@]}"
                            )
                            rm -rf "$TMP_BUILD_DIR"
                            log_success "AUR package '$apkg' built and installed."
                        done
                    else
                        log_warn "Skipped AUR package builds. Some features may require manual installation."
                    fi
                fi
            fi
        fi
    else
        log_success "All system and library dependencies are satisfied."
    fi
fi

# ==============================================================================
# Step 3: Apple SF Pro & SF Mono Fonts Registration
# ==============================================================================

log_step "[3/6] Installing Apple SF Pro & SF Mono fonts..."

if [ "$SKIP_FONTS" = true ]; then
    log_info "Skipping font installation (--no-fonts specified)."
else
    FONTS_SRC_DIR="${REPO_DIR}/assets/fonts"
    DEST_SF_PRO="${USER_FONTS_DIR}/SF-Pro"
    DEST_SF_MONO="${USER_FONTS_DIR}/SF-Mono"
    MANIFEST_FILE="${USER_FONTS_DIR}/.quickshell_notch_fonts_manifest"

    if [ "$DRY_RUN" = true ]; then
        log_dry "Would install SF Pro & SF Mono fonts to ${USER_FONTS_DIR}"
        log_dry "Would write manifest to ${MANIFEST_FILE}"
        log_dry "Would update fontconfig cache with fc-cache -f"
    else
        # Verify if local fonts exist; if not, download them
        if [ ! -d "$FONTS_SRC_DIR" ] || [ -z "$(ls -A "$FONTS_SRC_DIR" 2>/dev/null)" ]; then
            log_info "Local fonts not found in assets/fonts. Invoking font download helper..."
            bash "${REPO_DIR}/scripts/core/download_macos_fonts.sh"
        fi

        mkdir -p "$DEST_SF_PRO" "$DEST_SF_MONO"
        : > "$MANIFEST_FILE"

        if [ -d "$FONTS_SRC_DIR" ]; then
            for font_file in "$FONTS_SRC_DIR"/SF-Pro*; do
                if [ -f "$font_file" ]; then
                    fname="$(basename "$font_file")"
                    cp -f "$font_file" "$DEST_SF_PRO/$fname"
                    echo "$DEST_SF_PRO/$fname" >> "$MANIFEST_FILE"
                fi
            done

            for font_file in "$FONTS_SRC_DIR"/SFMono*; do
                if [ -f "$font_file" ]; then
                    fname="$(basename "$font_file")"
                    cp -f "$font_file" "$DEST_SF_MONO/$fname"
                    echo "$DEST_SF_MONO/$fname" >> "$MANIFEST_FILE"
                fi
            done
        fi

        if command -v fc-cache >/dev/null 2>&1; then
            log_info "Updating fontconfig cache (fc-cache -f)..."
            fc-cache -f "$USER_FONTS_DIR" >/dev/null 2>&1 || true
        fi
        log_success "Apple SF Pro and SF Mono fonts installed and registered."
    fi
fi

# ==============================================================================
# Step 4: Configuration & Templates Setup
# ==============================================================================

log_step "[4/6] Setting up configuration and runtime paths..."

if [ "$DRY_RUN" = true ]; then
    log_dry "Would setup ~/.config/quickshell ($INSTALL_MODE from $REPO_DIR)"
    log_dry "Would bootstrap Matugen templates in ~/.config/matugen"
    log_dry "Would create cache directories in ~/.cache/quickshell"
    log_dry "Would install quickshell-notch manager to ~/.local/bin/quickshell-notch"
else
    mkdir -p "${HOME}/.config"
    if [ "$REPO_DIR" = "$USER_CONFIG_DIR" ]; then
        log_info "Repository is already located at ~/.config/quickshell."
    elif [ -L "$USER_CONFIG_DIR" ]; then
        target="$(readlink -f "$USER_CONFIG_DIR")"
        if [ "$target" = "$REPO_DIR" ]; then
            log_info "~/.config/quickshell is already correctly symlinked to this repository."
        else
            log_info "Updating existing symlink ~/.config/quickshell -> $REPO_DIR"
            rm -f "$USER_CONFIG_DIR"
            ln -s "$REPO_DIR" "$USER_CONFIG_DIR"
        fi
    elif [ -d "$USER_CONFIG_DIR" ]; then
        BACKUP_DIR="${USER_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
        log_warn "Existing ~/.config/quickshell directory detected."
        action_name="linking"
        [ "$INSTALL_MODE" = "copy" ] && action_name="copying"
        if prompt_confirm "Back up existing directory to $(basename "$BACKUP_DIR") before ${action_name}?" "Y"; then
            mv "$USER_CONFIG_DIR" "$BACKUP_DIR"
            log_info "Backup created at $BACKUP_DIR"
            if [ "$INSTALL_MODE" = "copy" ]; then
                log_info "Copying files to ~/.config/quickshell..."
                cp -r "$REPO_DIR" "$USER_CONFIG_DIR"
            else
                log_info "Creating symlink ~/.config/quickshell -> $REPO_DIR"
                ln -s "$REPO_DIR" "$USER_CONFIG_DIR"
            fi
        else
            log_info "Keeping existing ~/.config/quickshell as-is."
        fi
    else
        if [ "$INSTALL_MODE" = "copy" ]; then
            log_info "Copying files to ~/.config/quickshell..."
            cp -r "$REPO_DIR" "$USER_CONFIG_DIR"
        else
            log_info "Creating symlink ~/.config/quickshell -> $REPO_DIR"
            ln -s "$REPO_DIR" "$USER_CONFIG_DIR"
        fi
    fi

    # 2. Matugen Templates
    MATUGEN_SRC="${REPO_DIR}/templates/matugen"
    MATUGEN_DEST="${HOME}/.config/matugen"
    if [ -d "$MATUGEN_SRC" ]; then
        mkdir -p "$MATUGEN_DEST"
        if [ ! -f "$MATUGEN_DEST/config.toml" ]; then
            log_info "Bootstrapping Matugen templates into ~/.config/matugen..."
            cp -r "$MATUGEN_SRC/"* "$MATUGEN_DEST/" 2>/dev/null || true
        else
            mkdir -p "$MATUGEN_DEST/templates"
            cp -rn "$MATUGEN_SRC/templates/"* "$MATUGEN_DEST/templates/" 2>/dev/null || true
        fi
    fi

    # 3. Cache & Runtime Directories
    mkdir -p "${HOME}/.cache/quickshell/thumbs"
    mkdir -p "${HOME}/.cache/wal"
    mkdir -p "${HOME}/.config/hypr"

    # 4. Permissions on scripts
    chmod +x "${USER_CONFIG_DIR}/scripts/core/"*.sh 2>/dev/null || true
    chmod +x "${USER_CONFIG_DIR}/scripts/desktop/"*.sh 2>/dev/null || true
    chmod +x "${USER_CONFIG_DIR}/scripts/hyprland/"*.sh 2>/dev/null || true
    chmod +x "${USER_CONFIG_DIR}/bin/quickshell-notch" 2>/dev/null || true
    chmod +x "${USER_CONFIG_DIR}/install.sh" "${USER_CONFIG_DIR}/uninstall.sh" 2>/dev/null || true

    # 5. CLI manager in ~/.local/bin pointing to user config bin
    mkdir -p "$USER_BIN_DIR"
    CLI_SOURCE="${USER_CONFIG_DIR}/bin/quickshell-notch"
    CLI_TARGET="${USER_BIN_DIR}/quickshell-notch"
    if [ -f "$CLI_SOURCE" ]; then
        rm -f "$CLI_TARGET"
        ln -sf "$CLI_SOURCE" "$CLI_TARGET"
        chmod +x "$CLI_TARGET"
        log_success "CLI helper installed to ${CLI_TARGET}"
    fi

    log_success "Configuration and templates initialized."
fi

# ==============================================================================
# Step 5: Hyprland Integration
# ==============================================================================

log_step "[5/6] Checking Hyprland integration..."

HYPR_LUA="${HOME}/.config/hypr/hyprland.lua"

LUA_SNIPPET="
-- ==============================================================================
-- QuickShell Notch Autostart & Persistence
-- ==============================================================================
hl.on(\"hyprland.start\", function()
    hl.exec_cmd(\"quickshell-notch launch\")
end)
pcall(dofile, os.getenv(\"HOME\") .. \"/.config/hypr/quickshell_hypr.lua\")
"

if [ -f "$HYPR_LUA" ]; then
    if grep -q "quickshell-notch launch" "$HYPR_LUA" 2>/dev/null || grep -q "launch_quickshell.sh" "$HYPR_LUA" 2>/dev/null; then
        log_success "Hyprland Lua configuration (${HYPR_LUA}) already includes QuickShell launch entry."
    else
        if [ "$AUTO_HYPRLAND" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                log_dry "Would append QuickShell startup lines to ${HYPR_LUA}"
            else
                echo "$LUA_SNIPPET" >> "$HYPR_LUA"
                log_success "Appended startup and persistence lines to ${HYPR_LUA}"
            fi
        else
            if [ "$DRY_RUN" = true ]; then
                log_dry "Would offer to append startup & persistence snippet to ${HYPR_LUA}"
            else
                echo -e "\n${C_BOLD}Hyprland Lua integration snippet for ${HYPR_LUA}:${C_RESET}"
                echo -e "${C_CYAN}${LUA_SNIPPET}${C_RESET}"
                if prompt_confirm "Automatically append these lines to ${HYPR_LUA}?" "Y"; then
                    echo "$LUA_SNIPPET" >> "$HYPR_LUA"
                    log_success "Added to ${HYPR_LUA}"
                fi
            fi
        fi
    fi
else
    log_info "No hyprland.lua found at ~/.config/hypr/."
    echo -e "Add this to your Hyprland configuration when ready:\n${C_CYAN}${LUA_SNIPPET}${C_RESET}"
fi

# ==============================================================================
# Step 6: Live Launch
# ==============================================================================

log_step "[6/6] Finalizing installation..."

# Check PATH for ~/.local/bin
if [[ ":$PATH:" != *":${USER_BIN_DIR}:"* ]]; then
    log_warn "~/.local/bin is not currently in your \$PATH."
    echo -e "  Add ${C_BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${C_RESET} to your ~/.bashrc or ~/.zshrc to use the 'quickshell-notch' command directly.\n"
fi

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ "$DRY_RUN" = false ]; then
    if prompt_confirm "You are in an active Hyprland session. Launch QuickShell Notch now?" "Y"; then
        log_info "Launching QuickShell Top Notch..."
        bash "${USER_CONFIG_DIR}/scripts/core/launch_quickshell.sh" >/dev/null 2>&1 &
        sleep 1
        log_success "QuickShell Notch launched!"
    fi
fi

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${C_GREEN}${C_BOLD}================================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}  QuickShell Top Notch successfully installed!  ${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}================================================================${C_RESET}\n"

echo -e "${C_BOLD}Quick Controls & Shortcuts:${C_RESET}"
echo -e "  ${C_CYAN}quickshell-notch launch${C_RESET}      Start or reload QuickShell Notch"
echo -e "  ${C_CYAN}quickshell-notch status${C_RESET}      Check process status & socket"
echo -e "  ${C_CYAN}quickshell-notch toggle${C_RESET}      Expand or collapse the notch"
echo -e "  ${C_CYAN}quickshell-notch nook${C_RESET}        Open MPRIS Media Controller (Tab 0)"
echo -e "  ${C_CYAN}quickshell-notch apps${C_RESET}        Open App Launcher (Tab 1)"
echo -e "  ${C_CYAN}quickshell-notch walls${C_RESET}       Open Wallpaper Selector (Tab 2)"
echo -e "  ${C_CYAN}quickshell-notch settings${C_RESET}    Open Notch Settings Window"
echo -e "  ${C_CYAN}quickshell-notch help${C_RESET}        Show full list of commands\n"

echo -e "To uninstall cleanly at any time, run: ${C_BOLD}./uninstall.sh${C_RESET}\n"
