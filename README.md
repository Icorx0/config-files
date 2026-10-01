# My Linux Dotfiles
This repository stores my personal configuration files (dotfiles) for various applications I use on Linux. The setup is designed to be fast, portable, and easy to manage using make.

## Quick Start on a New System
Setting up a new machine with these configurations is a simple two-step process.

1. Install Dependencies
Run the installer with sudo
```sudo ./install.sh```

2. Apply Configurations
Once the script is finished, run make apply. This will copy all the configurations from this repository to their correct locations in your home directory, backing up any existing files with a .bak extension.
```make apply```

That's it! Your new system is now configured.

## Daily Workflow
When you make a change to a local configuration file on your machine (e.g., you edit ~/.config/alacritty/alacritty.toml), follow these steps to save the changes back to the repository.

1. Collect Changes:
Run make collect to copy your changes from your system into this repository.
```make collect```

2. Commit and Push:
Commit the updated files to Git and push them to your remote.
```
git add .
git commit -m "feat: update alacritty theme"
git push
```

## Managed Software
This repository currently manages the configuration for:
- Alacritty - A fast, GPU-accelerated terminal emulator.
- Neovim - A modern, highly extensible text editor.
- Tmux - A terminal multiplexer.
- Hyprland - A dynamic tiling Wayland compositor.
- Waybar - A status bar for Wayland compositors.
- Zathura - A keyboard-driven document (PDF) viewer.
- Bash - The standard GNU Bourne-Again Shell.
- LaTeX - `texlive-full` plus Neovim snippets for math/document authoring.
- rclone - Cloud sync tool used to mirror `~/Documents/Notes` to Google Drive.

Each item is toggled by listing it in the `ENABLED` variable of your `.env`
file; `install.sh` then installs the matching packages.

## Themes
The `themes/` folder stores Catppuccin **Mocha** (dark) and **Latte** (light)
variants for Alacritty, Neovim, and Tmux.

Switching is a one-liner and needs **no commit**. Set `THEME` in your `.env`
(which is gitignored) and apply it:

```
THEME = mocha    # or: latte
```
```make theme```

The live configs import a generated theme file rather than inlining colors, so
a theme switch only rewrites generated files and never dirties a tracked
config. Alacritty picks it up instantly via `live_config_reload`, tmux is
reloaded by the script, and Neovim applies it on next start.

See `themes/README.md` for how the pieces fit together.

## Notes → Google Drive Sync (rclone)
A systemd user timer mirrors `~/Documents/Notes` to Google Drive once a day.

- `rclone/sync-notes.sh` - the mirror script (`rclone sync`, excludes `.git`).
- `systemd/user/rclone-sync-notes.{service,timer}` - daily oneshot + timer
  (`Persistent=true` catches up runs missed while the machine was off).

Setup on a new machine (after enabling `rclone` in `.env`):
```
rclone config                       # add a Google Drive remote named "DriveBruno"
ln -sf "$PWD/systemd/user/rclone-sync-notes.service" ~/.config/systemd/user/
ln -sf "$PWD/systemd/user/rclone-sync-notes.timer"   ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now rclone-sync-notes.timer
```
Note: your rclone token lives in `~/.config/rclone/rclone.conf` and is **not**
tracked here — never commit it.

Useful Links
[Alacritty Configuration](https://alacritty.org/config-alacritty.html)
[Neovim Documentation](https://neovim.io/doc/)
[lazy.nvim Plugin Manager](https://github.com/folke/lazy.nvim)
[rclone Documentation](https://rclone.org/docs/)
