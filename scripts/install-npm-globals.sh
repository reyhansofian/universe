#!/usr/bin/env bash
# Install global npm packages not managed by Nix
# Run this after setting up a new machine or WSL environment

set -euo pipefail

packages=(
  @aliou/pi-guardrails
  @mariozechner/pi-coding-agent
  @tmustier/pi-agent-teams
  @tmustier/pi-files-widget
  clawhub
  clinic
  pdf-brain
  pi-mcp-adapter
  pi-notify
  pi-powerline-footer
  pi-prompt-template-model
  pi-subagents
  pi-super-curl
  shitty-extensions
)

echo "Installing ${#packages[@]} global npm packages..."
npm install -g "${packages[@]}"
echo "Done."
