# Makefile for collecting dotfiles into a Git repository.
#
# Reads a .env file for an ENABLED variable (e.g., ENABLED = nvim hyprland)
# to determine which dotfiles to collect or apply.

# Include variables from .env file. This file must exist.
include .env

HOME := $(HOME)

.DEFAULT_GOAL := collect
.PHONY: collect apply theme

# Target to apply the Catppuccin variant named by THEME in .env.
# Theme switches only rewrite generated files, so they need no commit.
theme:
	@./themes/apply-theme.sh

# Target to copy dotfiles from the system into this repository.
collect:
	@echo "Collecting enabled dotfiles from system to repository..."

ifneq ($(filter tmux,$(ENABLED)),)
	# Tmux
	@echo "    Copying tmux config..."
	@mkdir -p tmux
	@cp $(HOME)/.tmux.conf tmux/tmux.conf
endif

ifneq ($(filter bash,$(ENABLED)),)
	# bashrc
	@echo "    Copying bashrc and bash_profile..."
	@mkdir -p bash
	@cp $(HOME)/.bashrc bash/bashrc
	@cp $(HOME)/.bash_profile bash/bash_profile
endif

ifneq ($(filter alacritty,$(ENABLED)),)
	# alacritty
	@echo "    Copying alacritty config..."
	@mkdir -p alacritty
	@cp $(HOME)/.config/alacritty/alacritty.toml alacritty/alacritty.toml
endif

ifneq ($(filter hyprland,$(ENABLED)),)
	# Hyprland
	@echo "    Copying hyprland config..."
	@rm -rf hypr/
	@cp -r $(HOME)/.config/hypr ./hypr
endif

ifneq ($(filter waybar,$(ENABLED)),)
	# Waybar
	@echo "    Copying waybar config..."
	@rm -rf waybar/
	@cp -r $(HOME)/.config/waybar ./waybar
endif

ifneq ($(filter nvim,$(ENABLED)),)
	# nvim
	@echo "    Copying nvim config directory..."
	@rm -rf nvim/
	@cp -r $(HOME)/.config/nvim ./nvim
endif

ifneq ($(filter zathura,$(ENABLED)),)
	# zathura
	@echo "    Copying zathura config directory..."
	@rm -rf zathura/
	@cp -r $(HOME)/.config/zathura ./zathura
endif
	@echo "Collection complete. You can now commit your changes."

# Target to apply dotfiles from this repository to the system.
apply:
	@echo "Applying enabled dotfiles from repository to system..."

ifneq ($(filter tmux,$(ENABLED)),)
	# Apply tmux.conf
	@echo "    Applying tmux config..."
	@if [ -f "$(HOME)/.tmux.conf" ]; then mv "$(HOME)/.tmux.conf" "$(HOME)/.tmux.conf.bak"; fi
	@cp ./tmux/tmux.conf $(HOME)/.tmux.conf
endif

ifneq ($(filter bash,$(ENABLED)),)
	# Apply bashrc
	@echo "    Applying bashrc..."
	@if [ -f "$(HOME)/.bashrc" ]; then mv "$(HOME)/.bashrc" "$(HOME)/.bashrc.bak"; fi
	@if [ -f "$(HOME)/.bash_profile" ]; then mv "$(HOME)/.bash_profile" "$(HOME)/.bash_profile.bak"; fi
	@cp ./bash/bashrc $(HOME)/.bashrc
	@cp ./bash/bash_profile $(HOME)/.bash_profile
endif

ifneq ($(filter alacritty,$(ENABLED)),)
	# Apply alacritty.toml
	@echo "    Applying alacritty config..."
	@mkdir -p $(HOME)/.config/alacritty
	@if [ -f "$(HOME)/.config/alacritty/alacritty.toml" ]; then mv "$(HOME)/.config/alacritty/alacritty.toml" "$(HOME)/.config/alacritty/alacritty.toml.bak"; fi
	@cp ./alacritty/alacritty.toml $(HOME)/.config/alacritty/alacritty.toml
endif

ifneq ($(filter hyprland,$(ENABLED)),)
	# Apply hyprland directory
	@echo "    Applying hyprland config directory..."
	@if [ -d "$(HOME)/.config/hypr" ]; then mv "$(HOME)/.config/hypr" "$(HOME)/.config/hypr.bak"; fi
	@cp -r ./hypr $(HOME)/.config/hypr
endif

ifneq ($(filter waybar,$(ENABLED)),)
	# Apply waybar directory
	@echo "    Applying waybar config directory..."
	@if [ -d "$(HOME)/.config/waybar" ]; then mv "$(HOME)/.config/waybar" "$(HOME)/.config/waybar.bak"; fi
	@cp -r ./waybar $(HOME)/.config/waybar
endif

ifneq ($(filter nvim,$(ENABLED)),)
	# Apply nvim directory
	@echo "    Applying nvim config directory..."
	@if [ -d "$(HOME)/.config/nvim" ]; then mv "$(HOME)/.config/nvim" "$(HOME)/.config/nvim.bak"; fi
	@cp -r ./nvim $(HOME)/.config/nvim
endif

ifneq ($(filter zathura,$(ENABLED)),)
	# Apply zathura directory
	@echo "    Applying zathura config directory..."
	@if [ -d "$(HOME)/.config/zathura" ]; then mv "$(HOME)/.config/zathura" "$(HOME)/.config/zathura.bak"; fi
	@cp -r ./zathura $(HOME)/.config/zathura
endif

	@echo "Application complete. Existing files were backed up with a .bak extension."
