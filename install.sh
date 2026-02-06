#!/bin/bash
# Install script for Claude Code + Ollama fallback setup

set -e

echo "Installing Claude Code Router + Ollama fallback..."
echo ""

# Install claude-code-router
echo "1. Installing claude-code-router..."
npm install -g @musistudio/claude-code-router

# Create config directory
echo "2. Setting up config..."
mkdir -p ~/.claude-code-router
cp config.json ~/.claude-code-router/config.json

# Install switching script
echo "3. Installing claude-switch script..."
mkdir -p ~/bin
cp claude-switch ~/bin/claude-switch
chmod +x ~/bin/claude-switch

# Add to PATH
if ! grep -q 'export PATH="$HOME/bin:$PATH"' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
    echo "   Added ~/bin to PATH in ~/.zshrc"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Run 'source ~/.zshrc' to apply PATH changes, then:"
echo "  claude-switch status  - Check current status"
echo "  claude-switch ollama  - Switch to local Ollama"
echo "  claude-switch anthropic - Switch to Anthropic API"
