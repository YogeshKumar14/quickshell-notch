#!/usr/bin/env bash
#
# uninstall.sh — Clean Uninstaller for QuickShell Top Notch
#
# Usage:
#   ./uninstall.sh [OPTIONS]
#
# Options:
#   -y, --yes          Non-interactive mode (auto-confirm prompts)
#   --dry-run          Simulate uninstallation without deleting files
#   --purge            Also purge configuration, user settings, and hyprland persistence files
#   --keep-fonts       Do not remove installed SF Pro / SF Mono fonts
#   -h, --help         Show this help message
#

set -euo pipefail

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

NON_INTERACTIVE=false
DRY_RUN=false
PURGE=false
KEEP_FONTS=false

show_help() {
    echo -e "${C_BOLD}QuickShell Top Notch — Uninstaller${C_RESET}

${C_BOLD}USAGE:${C_RESET}
    ./uninstall.sh [OPTIONS]

${C_BOLD}OPTIONS:${C_RESET}
    -y, --yes          Non-interactive mode (auto-confirm all prompts)
    --dry-run          Simulate removal without modifying any files or processes
    --purge            Remove all configuration (~/.config/quickshell), settings, and hyprland state
    --keep-fonts       Retain installed SF Pro and SF Mono fonts
    -h, --help         Show this help message and exit

${C_BOLD}EXAMPLES:${C_RESET}
    # Clean uninstall (keeps user configuration files):
    ./uninstall.sh

    # Complete purge:
    ./uninstall.sh --purge -y

    # Dry-run inspection:
    ./uninstall.sh --dry-run"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)
            NON_INTERACTIVE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --purge)
            PURGE=true
            ;;
        --keep-fonts)
            KEEP_FONTS=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: '$1'"
            echo "Run './uninstall.sh --help' for usage."
            exit 1
            ;;
    esac
    shift
done

prompt_confirm() {
    local message="$1"
    local default="${2:-Y}"

    if [ "$DRY_RUN" = true ] || [ "$NON_INTERACTIVE" = true ]; then
        if [ "$default" = "Y" ] || [ "$default" = "y" ]; then
            return 0
        else
            return 1
        fi
    fi

    local suffix="[Y/n]"
    [ "$default" = "N" ] && suffix="[y/N]"

    read -r -p "$(echo -e "${C_BOLD}${message}${C_RESET} ${suffix} ")" response || return 1
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG_DIR="${HOME}/.config/quickshell"
USER_FONTS_DIR="${HOME}/.local/share/fonts"
USER_BIN_DIR="${HOME}/.local/bin"
CACHE_DIR="${HOME}/.cache/quickshell"
MANIFEST_FILE="${USER_FONTS_DIR}/.quickshell_notch_fonts_manifest"

echo -e "${C_RED}${C_BOLD}"
cat <<'EOF'
  ___        _      _     ____  _          _ _ 
 / _ \ _   _(_) ___| | __/ ___|| |__   ___| | |
| | | | | | | |/ __| |/ /\___ \| '_ \ / _ \ | |
| |_| | |_| | | (__|   <  ___) | | | |  __/ | |
 \__\_\\__,_|_|\___|_|\_\|____/|_| |_|\___|_|_|
                U N I N S T A L L
EOF
echo -e "${C_RESET}"

if [ "$DRY_RUN" = true ]; then
    log_dry "Dry-run mode active. No files will be removed."
    echo ""
fi

if ! prompt_confirm "Are you sure you want to uninstall QuickShell Top Notch?" "Y"; then
    log_info "Uninstall aborted."
    exit 0
fi

# ==============================================================================
# Step 1: Terminate running daemon and helper processes
# ==============================================================================

log_step "[1/5] Stopping QuickShell Notch processes..."

if [ "$DRY_RUN" = true ]; then
    log_dry "Would terminate running quickshell and cava processes"
    log_dry "Would remove /tmp/quickshell-notch.sock"
else
    pkill -9 -f "/stream_audio_visualizer\.py" >/dev/null 2>&1 || true
    pkill -9 -x cava >/dev/null 2>&1 || true
    pkill -9 -x quickshell >/dev/null 2>&1 || true
    rm -f /tmp/quickshell-notch.sock
    log_success "Processes terminated."
fi

# ==============================================================================
# Step 2: Remove CLI helper
# ==============================================================================

log_step "[2/5] Removing CLI manager from ~/.local/bin..."

CLI_TARGET="${USER_BIN_DIR}/quickshell-notch"
if [ -L "$CLI_TARGET" ] || [ -f "$CLI_TARGET" ]; then
    if [ "$DRY_RUN" = true ]; then
        log_dry "Would remove ${CLI_TARGET}"
    else
        rm -f "$CLI_TARGET"
        log_success "Removed ${CLI_TARGET}"
    fi
else
    log_info "CLI manager not found in ${USER_BIN_DIR}."
fi

# ==============================================================================
# Step 3: Remove Fonts
# ==============================================================================

log_step "[3/5] Cleaning up fonts..."

if [ "$KEEP_FONTS" = true ]; then
    log_info "Skipping font removal (--keep-fonts specified)."
else
    if [ -f "$MANIFEST_FILE" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_dry "Would remove font files tracked in manifest (${MANIFEST_FILE})"
            log_dry "Would update fontconfig cache"
        else
            while IFS= read -r font_path; do
                if [ -n "$font_path" ] && [ -f "$font_path" ]; then
                    rm -f "$font_path"
                fi
            done < "$MANIFEST_FILE"
            rm -f "$MANIFEST_FILE"

            # Clean empty font subdirectories
            rmdir "${USER_FONTS_DIR}/SF-Pro" 2>/dev/null || true
            rmdir "${USER_FONTS_DIR}/SF-Mono" 2>/dev/null || true

            if command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f "$USER_FONTS_DIR" >/dev/null 2>&1 || true
            fi
            log_success "Apple SF Pro and SF Mono fonts removed."
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            log_dry "No font manifest found; would inspect and clean SF-Pro / SF-Mono directories if empty"
        else
            rm -f "${USER_FONTS_DIR}/SF-Pro"/SF-Pro* 2>/dev/null || true
            rm -f "${USER_FONTS_DIR}/SF-Mono"/SFMono* 2>/dev/null || true
            rmdir "${USER_FONTS_DIR}/SF-Pro" 2>/dev/null || true
            rmdir "${USER_FONTS_DIR}/SF-Mono" 2>/dev/null || true
            if command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f "$USER_FONTS_DIR" >/dev/null 2>&1 || true
            fi
            log_info "Cleaned up standard SF-Pro / SF-Mono directories."
        fi
    fi
fi

# ==============================================================================
# Step 4: Clean Cache and Runtime Files
# ==============================================================================

log_step "[4/5] Removing cached data..."

if [ -d "$CACHE_DIR" ]; then
    if [ "$DRY_RUN" = true ]; then
        log_dry "Would remove cache directory: ${CACHE_DIR}"
    else
        rm -rf "$CACHE_DIR"
        log_success "Removed ${CACHE_DIR}"
    fi
else
    log_info "Cache directory ${CACHE_DIR} is already clean."
fi

# Clean lock files
rm -f /tmp/quickshell_wallpaper_*.lock 2>/dev/null || true

# ==============================================================================
# Step 5: Clean Configuration
# ==============================================================================

log_step "[5/5] Handling configuration files..."

if [ -L "$USER_CONFIG_DIR" ]; then
    if [ "$DRY_RUN" = true ]; then
        log_dry "Would remove symlink: ${USER_CONFIG_DIR}"
    else
        rm -f "$USER_CONFIG_DIR"
        log_success "Removed symlink ${USER_CONFIG_DIR}"
    fi
elif [ -d "$USER_CONFIG_DIR" ]; then
    if [ "$PURGE" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            log_dry "Would remove directory: ${USER_CONFIG_DIR}"
        else
            if [ "$USER_CONFIG_DIR" = "$SCRIPT_DIR" ]; then
                cd "$HOME"
            fi
            rm -rf "$USER_CONFIG_DIR"
            log_success "Purged ${USER_CONFIG_DIR}"
        fi
    else
        log_info "User configuration preserved at ${USER_CONFIG_DIR}."
        echo -e "  To completely remove it, delete manually or run with ${C_BOLD}--purge${C_RESET}."
    fi
fi

# Hyprland persistence files cleanup if purged
if [ "$PURGE" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        log_dry "Would remove ~/.config/hypr/quickshell_hypr.conf and quickshell_hypr.lua"
    else
        rm -f "${HOME}/.config/hypr/quickshell_hypr.conf" "${HOME}/.config/hypr/quickshell_hypr.lua"
        log_success "Removed Hyprland persistence state files."
    fi
fi

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${C_GREEN}${C_BOLD}================================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}  QuickShell Top Notch uninstalled successfully.  ${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}================================================================${C_RESET}\n"

echo -e "${C_BOLD}Next Steps:${C_RESET}"
echo "  - If you added startup commands to ~/.config/hypr/hyprland.conf, remove:"
echo "      exec-once = bash ~/.config/quickshell/scripts/core/launch_quickshell.sh"
echo "      source = ~/.config/hypr/quickshell_hypr.conf"
echo "  - If you installed system packages (e.g. quickshell) specifically for the notch,"
echo "    you can remove them with: sudo pacman -R <package_name>"
echo ""
