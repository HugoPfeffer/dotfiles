#!/bin/bash

# Script to install CascadiaMono Nerd Font

# Set fonts directory
FONTS_DIR="$HOME/.local/share/fonts"

# Download CascadiaMono Nerd Font from GitHub releases
wget -P "$FONTS_DIR" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaMono.zip

# Change to fonts directory
cd "$FONTS_DIR" || exit

# Extract the font files
unzip CascadiaMono.zip

# Clean up the zip file
rm CascadiaMono.zip

# Refresh the font cache
fc-cache -fv

# Clear the terminal
clear
