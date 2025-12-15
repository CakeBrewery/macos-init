#!/bin/bash

# Exit on error, undefined vars, or pipe failures
set -euo pipefail

# Tells the script to split text only on Newlines (\n) and Tabs (\t)—but NOT on Spaces.
IFS=$'\n\t' 

# ----------------------------
# 0. SYSTEM TWEAKS
# ----------------------------
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false

# ----------------------------
# 1. PRE-FLIGHT
# ----------------------------

touch "$HOME/.zshrc" "$HOME/.zprofile"

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "Requesting Xcode Command Line Tools..."
  xcode-select --install || true
  echo "⚠️  Action Required: Complete the installer dialog, then press Enter."
  read -r
fi

# ----------------------------
# 2. HOMEBREW
# ----------------------------

if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Configure Path (Apple Silicon)
if [[ "$(uname -m)" == "arm64" ]]; then
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      if ! grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile"; then
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
      fi
  fi
else
  eval "$(/usr/local/bin/brew shellenv)" || true
fi

# ----------------------------
# 3. WORKSPACE & TOOLS
# ----------------------------

mkdir -p "$HOME/workspace"

brew install --cask orbstack || true
brew install git gh || true

# Vim Config
if [[ ! -f "$HOME/.vimrc" ]]; then
  curl -fsSL https://raw.githubusercontent.com/CakeBrewery/Vim-Configuration/master/.vimrc \
    -o "$HOME/.vimrc"
fi

# ----------------------------
# 4. LANGUAGES (Strict Mode Disabled)
# ----------------------------

# Disable strict mode for SDKMAN/NVM to prevent crashes
set +u 

# --- JAVA (SDKMAN) ---
if [[ ! -d "$HOME/.sdkman" ]]; then
  curl -fsSL https://get.sdkman.io | bash
fi

# Load SDKMAN
source "$HOME/.sdkman/bin/sdkman-init.sh"

# FORCE UPDATE: This fixes the "version not available" error in scripts
sdk update

if ! sdk list java | grep -q "25.0.1-zulu.*installed"; then
  # The '|| true' ensures that if it's already there but grep missed it, we don't crash
  sdk install java 25.0.1-zulu || true
fi

# --- NODE (NVM) ---
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

# Configure NVM in .zshrc
if ! grep -q 'NVM_DIR=.*\.nvm' "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node
if ! nvm ls 24 &>/dev/null; then
  nvm install 24 || nvm install --lts
fi

# Re-enable strict mode
set -u

# ----------------------------
# 5. REACT NATIVE & AI
# ----------------------------

brew install watchman || true

if ! command -v eas &>/dev/null; then
  npm install -g eas-cli
fi

brew install codex
brew install gemini-cli || true
brew install --cask claude-code || true

if [ ! -d "/Applications/Cursor.app" ]; then
    curl -fsS https://cursor.com/install | bash || true
fi

# ----------------------------
# 6. SSH SETUP
# ----------------------------

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  echo ""
  read -p "Generate SSH key for GitHub? (y/n) " -n 1 -r
  echo ""
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    read -p "Enter email: " SSH_EMAIL
    if [[ -n "$SSH_EMAIL" ]]; then
        ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
        pbcopy < "$HOME/.ssh/id_ed25519.pub"
        echo "✅ Public key copied to clipboard!"
        open "https://github.com/settings/ssh/new"
        echo "👉 Paste the key into the browser."
    fi
  fi
fi

echo "Setup complete. Restart your terminal."