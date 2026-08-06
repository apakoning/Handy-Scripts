#!/bin/bash
set -e

NERD_FONTS_VERSION="v3.1.1"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/NerdFonts.zip"
TMP_DIR="/tmp/nerd-fonts-full"
FONT_DIR="/usr/share/fonts/nerd-fonts"

echo "🔧 Creating temp and font directories..."
sudo mkdir -p "$TMP_DIR"
sudo mkdir -p "$FONT_DIR"

echo "⬇️ Downloading FULL Nerd Fonts Pack... (~2.7GB)"
cd "$TMP_DIR"
wget --content-disposition "$DOWNLOAD_URL"

echo "📦 Extracting and installing fonts..."
ZIP_FILE=$(ls | grep NerdFonts.zip)
sudo unzip -o "$ZIP_FILE" -d "$FONT_DIR"

sudo chmod -R 644 "$FONT_DIR"/*
sudo fc-cache -fv

echo "✅ All Nerd Fonts installed system-wide to: $FONT_DIR"

