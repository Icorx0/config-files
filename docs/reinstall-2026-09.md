# Reinstall log — September 2026 (Ubuntu 26.04.1 "resolute" on both machines)

What was done, in order, and what to repeat next time. Secrets are never stored
here — only where they live.

## Machines

| | ThinkPad (`icorx0-thinkpad`) | Desktop (`icorx0-desktop`, ssh `desktop`) |
|---|---|---|
| OS | Ubuntu 26.04.1 Desktop (GNOME 50) | Ubuntu 26.04.1 Desktop, run **headless** |
| Disk | nvme0n1: p1 EFI `3A74-715B`, p3 BitLocker (Windows), p5 `/boot` ext4 `7723fd25…` (5.7G), p6 LUKS2 `cea35846…` → LVM `ubuntu-vg/ubuntu-lv` (/) | nvme0n1 LVM (no encryption); `/data` = sdb1 `241ec4cd…` (`nofail`) |
| Boot | UEFI + shim/GRUB, **dracut** initramfs (not initramfs-tools) | UEFI, dracut |
| Tailscale | — | `100.115.244.9` / `desktop.tail95f537.ts.net` |

## ThinkPad

1. **Fresh install** 2026-09-18 over the old 22.04 (backup of the old home was
   taken to the desktop first).
2. **/boot grown to 5.7G** by merging the free 4G p4 into p5:
   copy /boot out → `sfdisk` new p5 start → `partx -d/-a` (NOT `partx -u`, it
   cannot move a start) → `mkfs.ext4 -U <old uuid>` so fstab/GRUB keep working →
   copy back → `update-grub`.
   Gotcha: EBUSY on the partition was snapd's preserved mount namespaces;
   fix with `sudo /usr/lib/snapd/snap-discard-ns <snap>` for each snap.
3. **Restored from the backup** (scope chosen on purpose): Downloads, Documents,
   Pictures, `.aws`, ReddVest, `Projects/config-files` only, Brave profile,
   `.claude`, `.ssh`, `.vscode` + `~/.config/Code/User`, git identity
   (`.gitconfig*`), `.config/gh`, `.gmail-mcp`, `.config/google-calendar-mcp`,
   `.gnupg`. `gh` needs `gh auth login` again (its token lived in the old keyring).
4. **Programs**: `~/restore/install-programs.sh` (sudo, idempotent) — Ubuntu
   archive + vscode/chrome/terraform/nodesource/cloudflared/dbeaver/docker
   repos, draw.io snap, Spotify + Network Displays flatpaks, npm tools,
   VS Code extensions. **No games on the ThinkPad** (no Steam/Minecraft/playit),
   no Zoom/Blender/OBS/qBittorrent.
   Never install `grub-pc` (BIOS GRUB, would remove the EFI one) or
   `cryptsetup-initramfs` (drags initramfs-tools back; can break LUKS unlock).
5. **Docker**: old volumes exported as tarballs → `~/restore/restore-docker.sh`
   recreates them in Docker Engine (Docker Desktop is gone).
6. **config-files** applied (`make apply && make theme`, `ENABLED = nvim tmux
   alacritty`, `THEME = mocha`). bash deliberately NOT enabled (its
   `bash_profile` would shadow Ubuntu's `.profile`, which puts `~/.local/bin`
   on PATH).
7. **Neovim 0.12.5 user-level** at `~/.local/opt/nvim` → `~/.local/bin/nvim`
   (official tarball, sha256 from the GitHub release). 26.04 apt ships 0.11.6,
   which crashes nvim-treesitter's main branch. Never `apt install neovim`.
8. **Lid close = lock, no suspend** (`system/logind.conf.d/10-lid-lock.conf`).
9. **Full snapshot before the first reboot** (whole home + `/etc` + package
   lists, sha256 verified) was kept on the desktop until the ThinkPad had
   rebooted fine, then deleted. Only the **LUKS header backup** stays:
   desktop `~/Backups/thinkpad-luks-header/` (README has the restore command).
   Take one again after any passphrase or keyslot change:
   `sudo cryptsetup luksHeaderBackup /dev/nvme0n1p6 --header-backup-file …`.
10. **ReddVest moved to the desktop** (`~/ReddVest`): code with its git state,
    the `includeIf gitdir:` identity, DB restored from the pg_dumpall, Claude
    sessions. Postgres published on `127.0.0.1` only. The laptop keeps no
    ReddVest data and no Docker data.

## Desktop

1. **Backup** of the old 24.04 server (home, 28 Docker volumes, local images)
   to `/data`, plus an OldJobs copy on the ThinkPad; whole nvme wiped.
2. **Install 26.04.1 Desktop, run headless** (costs the same idle power as the
   old server + `gui-on`):
   - `systemctl set-default multi-user.target`
   - sleep/suspend/hibernate targets masked
   - GDM autologin `icorx0` (`/etc/gdm3/custom.conf`)
   - NVIDIA (RTX 2060, the only GPU) kept off at boot — needs BOTH
     `/etc/modprobe.d/gpu-off.conf` (blacklist nvidia, nvidia_drm,
     nvidia_modeset, nvidia_uvm) AND `/etc/dracut.conf.d/gpu-off.conf`
     (`omit_drivers+=" nvidia nvidia_drm nvidia_modeset nvidia_uvm "`), then
     `dracut --regenerate-all -f`. Check after kernel/driver updates:
     `sudo lsinitrd | grep nvidia`.
   - `/usr/local/bin/gui-on` (modprobe by name + isolate graphical.target),
     `gui-off`, `gui-status`.
3. **Old SSH host keys restored** so clients' known_hosts still match.
4. **Restored** home, Docker volumes and images from `/data`, then deleted
   the `/data` backup. .NET 8 is gone from 26.04 → `dotnet-sdk-10.0`.
   Minecraft launcher from the tar.gz in `/opt` (the .deb needs
   `libgdk-pixbuf2.0-0`, renamed in 26.04). Neovim user-level as above.
5. ThinkPad-only data removed from the desktop; osu! songs and the ThinkPad's
   Minecraft worlds + mods merged into the desktop's.
6. **Reeco**: the ThinkPad's working copy is the one kept; its secrets live
   inside the project folder.
7. **Google Drive (rclone remote `DriveBruno`)**:
   - `~/.local/bin/familia-sync` — Drive `Familia` → `~/Documents/Familia`
     (`copy --ignore-existing`, never `sync`, so local-only files survive).
   - `~/.local/bin/familia-upload` — local → Drive, add-only.
   - Toshiba external disk (NTFS, damaged indexes → mount `ntfs-3g -o ro`)
     merged into `~/Documents/Familia` by content hash (MD5), no replacements.
8. **playit** (game-server tunnel) belongs here, not on the ThinkPad:
   `~/install-playit.sh` (sudo), then claim the agent on playit.gg.
9. Passwordless sudo was removed 2026-09-19; admin steps are run by hand.

## Gotchas worth remembering

- Third-party apt repos: the keyring filename must match what the `.sources`
  file's `Signed-By:` points to, or apt says "not signed".
- `rsync` is not guaranteed on a fresh 26.04 desktop; `apt remove rsync` also
  removes `ubuntu-standard`.
- A Ventoy USB (NTFS) that was pulled without ejecting mounts only read-only
  ("volume is dirty"); `sudo ntfsfix -d /dev/sdX1` clears it.
- rclone with the shared client ID is slow on Drive (~1–2 MiB/s); an own
  OAuth client (consent screen "In production") and a current rclone help.
