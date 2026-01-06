#!/usr/bin/env bash
# Dedicated installer for Composer
# Downloads latest stable composer.phar and installs to /usr/local/bin
set -euo pipefail

INSTALL_DIR="${COMPOSER_INSTALL_DIR:-/usr/local/bin}"
COMPOSER_URL="https://getcomposer.org/download/latest-stable/composer.phar"

echo "[composer] Downloading latest stable composer.phar..."

# Download to temp file
TMP_FILE="$(mktemp)"
trap "rm -f '$TMP_FILE'" EXIT

if ! curl -fsSL "$COMPOSER_URL" -o "$TMP_FILE"; then
  echo "[composer] Error: Failed to download from $COMPOSER_URL" >&2
  exit 1
fi

# Verify it's a valid phar by checking version
echo "[composer] Verifying downloaded phar..."
if ! php "$TMP_FILE" --version >/dev/null 2>&1; then
  echo "[composer] Error: Downloaded file is not a valid composer.phar" >&2
  exit 1
fi

# Get version
COMPOSER_VERSION="$(php "$TMP_FILE" --version 2>/dev/null | head -1 || echo 'unknown')"
echo "[composer] Downloaded: $COMPOSER_VERSION"

# Get current version
CURRENT_VERSION="$(command -v composer >/dev/null 2>&1 && composer --version 2>/dev/null | head -1 || echo '<none>')"
echo "[composer] Current: $CURRENT_VERSION"

# Install composer.phar
echo "[composer] Installing to $INSTALL_DIR/composer..."

if [ -w "$INSTALL_DIR" ]; then
  # User has write access
  cp "$TMP_FILE" "$INSTALL_DIR/composer"
  chmod 755 "$INSTALL_DIR/composer"
elif command -v sudo >/dev/null 2>&1; then
  # Need sudo
  echo "[composer] Requires sudo to install to $INSTALL_DIR"
  sudo cp "$TMP_FILE" "$INSTALL_DIR/composer"
  sudo chmod 755 "$INSTALL_DIR/composer"
else
  echo "[composer] Error: Cannot write to $INSTALL_DIR and sudo not available" >&2
  echo "[composer] Try: COMPOSER_INSTALL_DIR=~/.local/bin $0" >&2
  exit 1
fi

# Verify installation
NEW_VERSION="$(composer --version 2>/dev/null | head -1 || echo '<failed>')"
echo "[composer] Installed: $NEW_VERSION"

if [ "$NEW_VERSION" = "<failed>" ]; then
  echo "[composer] Error: Installation verification failed" >&2
  exit 1
fi

echo "[composer] ✓ Installation successful"
