#!/bin/bash
# Reinstall the ThinkPad's programs on Ubuntu 26.04 "resolute".
# Built from the old 22.04 box's package lists, checked against the 26.04
# archive on 2026-09-18 (see docs/reinstall-2026-09.md). Dotfiles are separate:
# `make apply && make theme` after this.
#
#   sudo ./install-programs.sh                      # everything
#   sudo WITH_TEXLIVE=0 ./install-programs.sh       # skip texlive-full (~6 GB)
#
# Safe to re-run: every step is idempotent. Failures are collected and printed
# at the end instead of aborting the whole run.
#
# DELIBERATELY NOT INSTALLED (they were on the old box but would hurt here):
#   grub-pc, grub-pc-bin, grub-gfxpayload-lists
#       BIOS GRUB. On this UEFI machine apt would REMOVE grub-efi-amd64 to install them.
#   cryptsetup-initramfs
#       Belongs to initramfs-tools. 26.04 boots with dracut; this would drag
#       initramfs-tools back in and can break unlocking the LUKS root at boot.
#   docker-desktop
#       Replaced by plain Docker Engine. Project containers and volumes live on
#       the desktop, not on the ThinkPad.
#   linux-generic-hwe-22.04, libicu70, libllvm13, libffi7, libx264-163 ...
#       22.04-only kernel meta / old library sonames. Pulled in by name on 22.04 only.
#   neovim (apt)
#       26.04 ships 0.11.6, but the config-files nvim setup uses nvim-treesitter's
#       main branch, which requires Neovim >= 0.12. Neovim 0.12.5 is installed
#       user-level at ~/.local/opt/nvim (-> ~/.local/bin/nvim) from the official,
#       checksum-verified release tarball. apt's 0.11 would only shadow/confuse it.
#   zoom, minecraft-launcher, playit, blender, OBS, qBittorrent, steam
#       Dropped by the user on 2026-09-19 (playit lives on the desktop instead).
#   ubuntu-desktop etc., PPAs for alacritty/neovim/inkscape/obs/libheif
#       The 26.04 archive versions are newer than what those PPAs offered for 22.04.

set -u
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
U="${SUDO_USER:-icorx0}"
UH=$(getent passwd "$U" | cut -d: -f6)
WITH_TEXLIVE="${WITH_TEXLIVE:-1}"
NODE_MAJOR="${NODE_MAJOR:-22}"   # old box had 20.x, which is EOL since Apr 2026; 22 is the nearest LTS
FAILED=()
step(){ echo; echo "=== $* ==="; }
try(){ "$@" || { echo "!! FAILED: $*"; FAILED+=("$*"); }; }
export DEBIAN_FRONTEND=noninteractive

install -d -m 0755 /etc/apt/keyrings
addkey(){ # name url  -> /etc/apt/keyrings/name.{asc|gpg}
  local tmp; tmp=$(mktemp)
  curl -fsSL "$2" -o "$tmp" || { echo "!! key download failed: $2"; FAILED+=("key $1"); rm -f "$tmp"; return 1; }
  if head -c 10 "$tmp" | grep -q -- '-----BEGIN'; then install -m 0644 "$tmp" "/etc/apt/keyrings/$1.asc"
  else install -m 0644 "$tmp" "/etc/apt/keyrings/$1.gpg"; fi
  rm -f "$tmp"
}
keyfile(){ ls /etc/apt/keyrings/$1.* 2>/dev/null | head -1; }
repo(){ # name uri suites [components]
  local k; k=$(keyfile "$1")
  {
    echo "Types: deb"; echo "URIs: $2"; echo "Suites: $3"
    [ -n "${4:-}" ] && echo "Components: $4"
    echo "Architectures: amd64"; echo "Signed-By: $k"
  } > "/etc/apt/sources.list.d/$1.sources"
}

step "1. Third-party apt repositories"
addkey docker     https://download.docker.com/linux/ubuntu/gpg             && repo docker     https://download.docker.com/linux/ubuntu resolute stable
addkey vscode     https://packages.microsoft.com/keys/microsoft.asc        && repo vscode     https://packages.microsoft.com/repos/code stable main
addkey google-chrome https://dl.google.com/linux/linux_signing_key.pub        && repo google-chrome https://dl.google.com/linux/chrome/deb/ stable main
addkey hashicorp  https://apt.releases.hashicorp.com/gpg                   && repo hashicorp  https://apt.releases.hashicorp.com resolute main
addkey nodesource https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key && repo nodesource https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main
addkey cloudflared https://pkg.cloudflare.com/cloudflare-public-v2.gpg      && repo cloudflared https://pkg.cloudflare.com/cloudflared any main
addkey dbeaver    https://dbeaver.io/debs/dbeaver.gpg.key                  && repo dbeaver    https://dbeaver.io/debs/dbeaver-ce /
# Brave and Tailscale repos are already configured on this install.
try apt-get update

step "2. Ubuntu archive packages"
PKGS=(
  # build / dev
  build-essential g++ clang lld cmake ninja-build make pkg-config libssl-dev libgtk-3-dev
  git direnv fzf tmux alacritty wl-clipboard python3-pip python3-venv openjdk-21-jdk   # NOT neovim: see header
  postgresql-client
  # cli / media
  aria2 ffmpeg mpv yt-dlp fastfetch btop
  # system
  cifs-utils flatpak openssh-server minidlna xvfb libfuse2t64
  # desktop apps
  inkscape remmina
  # codecs / fonts / hw
  heif-gdk-pixbuf heif-thumbnailer libheif-examples
  fonts-freefont-ttf fonts-ibm-plex fonts-indic fonts-ipafont-gothic fonts-tlwg-loma-otf
  fonts-unifont fonts-wqy-zenhei xfonts-cyrillic xfonts-scalable xserver-xorg-input-wacom
  pipewire-audio-client-libraries
  # libs the old box had installed by name for Electron/AppImage/game apps
  libdbus-glib-1-2 libglu1-mesa libmanette-0.2-0 libopengl0 libwoff1 libxcb-cursor0
)
[ "$WITH_TEXLIVE" = 1 ] && PKGS+=(texlive-full)
try apt-get install -y "${PKGS[@]}"

step "3. Third-party packages"
try apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
try apt-get install -y code google-chrome-stable terraform nodejs cloudflared dbeaver-ce
try usermod -aG docker "$U"

step "4. Snaps"
try snap install drawio

step "5. Flatpaks (per-user, so app data lives in ~/.var like before)"
sudo -u "$U" flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
for a in com.spotify.Client org.gnome.NetworkDisplays; do
  try sudo -u "$U" flatpak install --user -y --noninteractive flathub "$a"
done
# Spotify "can't play this right now" fix from the old box
SD="$UH/.local/share/applications/com.spotify.Client.desktop"
SRC="$UH/.local/share/flatpak/exports/share/applications/com.spotify.Client.desktop"
if [ -f "$SRC" ] && [ ! -f "$SD" ]; then
  sudo -u "$U" mkdir -p "$(dirname "$SD")"
  sed 's#^Exec=\(.*com.spotify.Client\)#Exec=\1 --audio-api=pulseaudio#' "$SRC" | sudo -u "$U" tee "$SD" >/dev/null
fi

step "6. Node global tools (as $U, into ~/.local — no sudo npm)"
sudo -u "$U" npm config set prefix "$UH/.local"
try sudo -u "$U" npm i -g corepack tree-sitter-cli
try sudo -u "$U" env PATH="$UH/.local/bin:$PATH" corepack enable --install-directory "$UH/.local/bin"

step "7. VS Code extensions"
for e in anthropic.claude-code eamodio.gitlens; do try sudo -u "$U" code --install-extension "$e"; done

echo
echo "================================================================"
if [ ${#FAILED[@]} -eq 0 ]; then echo " ALL STEPS OK"; else echo " FAILED STEPS (${#FAILED[@]}):"; printf '   - %s\n' "${FAILED[@]}"; fi
echo " Log out and back in (or reboot) so the docker group applies."
echo "================================================================"
