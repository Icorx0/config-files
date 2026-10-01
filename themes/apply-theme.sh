#!/bin/bash
#
# Applies the Catppuccin variant named by THEME in .env to the enabled configs.
#
# Each live config imports a theme file at a fixed path; this script decides
# which variant lands there. Switching themes therefore never edits a tracked
# config -- set THEME in .env (which is gitignored) and re-run.
#
#   THEME = mocha   ->  dark
#   THEME = latte   ->  light

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE file not found."
    echo "Please create one, for example:"
    echo "THEME = mocha"
    exit 1
fi

THEME=$(grep '^[[:space:]]*THEME' "$ENV_FILE" | cut -d '=' -f 2- | xargs)
ENABLED=$(grep '^[[:space:]]*ENABLED' "$ENV_FILE" | cut -d '=' -f 2- | xargs)

if [ -z "$THEME" ]; then
    echo "Error: The THEME variable is not set in your .env file."
    echo "Add one, for example: THEME = mocha"
    exit 1
fi

case "$THEME" in
    mocha | latte) ;;
    *)
        echo "Error: unknown THEME '$THEME'. Valid values: mocha, latte."
        exit 1
        ;;
esac

# Copy a theme snippet into place, failing loudly if the variant is missing.
deploy() {
    local src="$1" dest="$2" label="$3"
    if [ ! -f "$src" ]; then
        echo "Error: missing theme file $src"
        exit 1
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "    $label -> $dest"
}

echo "Applying theme: $THEME"

if [[ " $ENABLED " == *" alacritty "* ]]; then
    deploy "$REPO_DIR/themes/alacritty-$THEME.toml" \
           "$HOME/.config/alacritty/theme.toml" "alacritty"
fi

if [[ " $ENABLED " == *" tmux "* ]]; then
    deploy "$REPO_DIR/themes/tmux-$THEME.conf" \
           "$HOME/.tmux-theme.conf" "tmux"
fi

if [[ " $ENABLED " == *" nvim "* ]]; then
    deploy "$REPO_DIR/themes/nvim-$THEME.lua" \
           "$HOME/.config/nvim/lua/theme.lua" "nvim"
fi

# Alacritty reloads imported files on its own (live_config_reload). tmux needs a
# nudge, and only if a server is actually running.
if [[ " $ENABLED " == *" tmux "* ]] && tmux info &> /dev/null; then
    tmux source-file "$HOME/.tmux.conf"
    echo "    tmux reloaded"
fi

echo "Theme applied. Already-open nvim instances need a restart."
