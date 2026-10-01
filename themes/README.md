## Themes

Saved Catppuccin theme configs: **Mocha** (dark) and **Latte** (light).

### Switching

Set `THEME` in the repo's `.env`, then apply it:

```
THEME = mocha    # or: latte
```
```
make theme       # or: ./themes/apply-theme.sh
```

`.env` is gitignored and the files the script writes are generated rather than
tracked, so **switching themes never produces a commit**. It also means the
active theme is per-machine, which is usually what you want.

### How it works

Each live config imports a theme file at a fixed path instead of inlining
colors. `apply-theme.sh` reads `THEME` and copies the matching variant there,
honouring the same `ENABLED` list as the makefile.

| Source                  | Deployed to                      | Wired up by                      |
| ----------------------- | -------------------------------- | -------------------------------- |
| `alacritty-$THEME.toml` | `~/.config/alacritty/theme.toml` | `import` in `alacritty.toml`     |
| `tmux-$THEME.conf`      | `~/.tmux-theme.conf`             | `source-file` in `.tmux.conf`    |
| `nvim-$THEME.lua`       | `~/.config/nvim/lua/theme.lua`   | `require('theme')` in `init.lua` |

Reload behaviour: Alacritty is instant (`live_config_reload` watches imported
files), tmux is reloaded by the script if a server is running, and
**already-open Neovim instances keep the old theme until restarted**.

### Adding a variant

Drop `alacritty-<name>.toml`, `tmux-<name>.conf` and `nvim-<name>.lua` in here,
then add `<name>` to the `case` guard in `apply-theme.sh`.

### Gotchas

- Don't put `[colors.*]` back into `alacritty/alacritty.toml`. Alacritty lets
  the importing file override imported values, so it would pin the palette and
  silently defeat the switcher.
- `nvim/lua/theme.lua` is gitignored. `make collect` re-copies the whole nvim
  directory, so without that ignore the generated file would get tracked and
  reintroduce the churn this setup removes.
