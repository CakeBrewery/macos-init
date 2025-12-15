#!/bin/bash

# -- 0. SYSTEM TWEAKS --
# Disable key-repeat for Vim/VSCode
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
echo "macOS key repeat enabled (requires logout/restart to fully take effect)."

# -- 1. PRE-FLIGHT --

# Create .zshrc
touch ~/.zshrc

# Install Xcode Tools
if ! xcode-select -p &> /dev/null; then
    xcode-select --install
    read -p "Press Enter once the installation dialog is complete..."
fi

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Config Apple Silicon Path
if [[ $(uname -m) == 'arm64' ]] && ! grep -q "opt/homebrew/bin/brew" ~/.zprofile; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# -- 2. WORKSPACE SETUP --
mkdir -p "$HOME/workspace"

# -- 3. CORE TOOLS --
brew install --cask orbstack
brew install git gh

# Config Vim
[ -f "$HOME/.vimrc" ] && cp "$HOME/.vimrc" "$HOME/.vimrc.bak"
curl -sL https://raw.githubusercontent.com/CakeBrewery/Vim-Configuration/master/.vimrc -o "$HOME/.vimrc"

# -- 4. LANGUAGES --

# Install Java (SDKMAN)
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 25.0.1-zulu

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node v24
nvm install 24
nvm alias default 24

# -- 5. REACT NATIVE / EXPO --
brew install watchman
npm install -g eas-cli

# -- 6. AI AGENTS --
npm i -g @openai/codex
brew install gemini-cli
curl https://cursor.com/install -fsS | bash
brew install --cask claude-code

# -- 7. SSH & GITHUB CONFIG --
echo ""
read -p "Do you want to generate an SSH key and configure GitHub now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Prompt for SSH email
    read -p "Enter your public email address for SSH key generation: " SSH_EMAIL

    # Generate key
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        echo "Generating SSH Key for $SSH_EMAIL..."
        ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
    else
        echo "Existing SSH key found."
    fi
    
    # Copy to clipboard
    pbcopy < "$HOME/.ssh/id_ed25519.pub"
    echo "✅ Public key copied to clipboard!"
    
    # Open GitHub Settings
    echo "Opening GitHub settings page..."
    open "https://github.com/settings/ssh/new"
    
    echo "👉 PASTE the key into the 'Key' field in the browser window that just opened."
fi

echo "Setup complete. Please restart your terminal."
