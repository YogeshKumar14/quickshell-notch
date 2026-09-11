# Maintainer: Yogesh Kumar <yogesh@example.com>
pkgname=quickshell-notch
pkgver=2.2.0
pkgrel=1
pkgdesc="Apple-inspired dynamic top notch status bar and control center for Hyprland built with QuickShell"
arch=('any')
url="https://github.com/YogeshKumar14/quickshell-notch"
license=('MIT')
depends=(
    'quickshell'
    'hyprland'
    'cava'
    'pipewire'
    'pipewire-pulse'
    'wireplumber'
    'matugen'
    'awww'
    'playerctl'
    'socat'
    'grim'
    'ffmpeg'
    'libnotify'
    'brightnessctl'
    'networkmanager'
    'bluez'
    'bluez-utils'
    'swaync'
    'python'
    'python-pillow'
    'python-dbus'
    'python-gobject'
    'python-requests'
    'qt6-5compat'
    'qt6-svg'
    'fontconfig'
    'ttf-jetbrains-mono-nerd'
)
optdepends=(
    'wallust-bin: Alternative color palette generation engine'
    'kitty: Default terminal configuration for launcher profiles'
    'wofi: Application launcher menu fallback'
)
makedepends=('git')
install=packaging/quickshell-notch.install
source=()
sha256sums=()

package() {
    local src_root
    if [ -d "$srcdir/$pkgname-$pkgver" ]; then
        src_root="$srcdir/$pkgname-$pkgver"
    elif [ -d "$srcdir/$pkgname" ]; then
        src_root="$srcdir/$pkgname"
    elif [ -f "$startdir/shell.qml" ]; then
        src_root="$startdir"
    else
        src_root="$srcdir"
    fi

    local sharedir="$pkgdir/usr/share/quickshell-notch"
    local fontsdir="$pkgdir/usr/share/fonts/quickshell-notch"

    mkdir -p "$sharedir" "$fontsdir" "$pkgdir/usr/bin"

    # Install CLI helper
    install -Dm755 "$src_root/bin/quickshell-notch" "$pkgdir/usr/bin/quickshell-notch"

    # Install Core Shell and Configurations
    install -Dm644 "$src_root/shell.qml" "$sharedir/shell.qml"
    install -Dm644 "$src_root/notch_settings.json" "$sharedir/notch_settings.json"
    [ -f "$src_root/current_wallpaper" ] && install -Dm644 "$src_root/current_wallpaper" "$sharedir/current_wallpaper"

    # Copy Components, Theme, Scripts, Templates
    cp -r "$src_root/components" "$sharedir/"
    cp -r "$src_root/theme" "$sharedir/"
    cp -r "$src_root/scripts" "$sharedir/"
    cp -r "$src_root/templates" "$sharedir/"

    # Clean any local pycache from the package
    find "$sharedir" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

    # Copy SVG icons and Fonts
    mkdir -p "$sharedir/assets"
    if [ -d "$src_root/assets/icons" ]; then
        cp -r "$src_root/assets/icons" "$sharedir/assets/"
    fi
    if [ -d "$src_root/assets/fonts" ]; then
        cp -r "$src_root/assets/fonts" "$sharedir/assets/"
        find "$src_root/assets/fonts" -type f \( -name "*.otf" -o -name "*.ttf" \) -exec install -Dm644 {} "$fontsdir/" \;
    fi

    # Set executable permissions on scripts
    find "$sharedir/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod 755 {} \;

    # Desktop entry & License & Docs
    if [ -f "$src_root/packaging/quickshell-notch.desktop" ]; then
        install -Dm644 "$src_root/packaging/quickshell-notch.desktop" "$pkgdir/usr/share/applications/quickshell-notch.desktop"
    fi
    install -Dm644 "$src_root/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 "$src_root/README.md" "$pkgdir/usr/share/doc/$pkgname/README.md"
}
