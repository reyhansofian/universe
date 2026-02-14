#!/usr/bin/env bash
# Set up Pi coding agent config with secrets from SOPS
# Run this after `home-manager switch` on a new machine
#
# Prerequisites: sops, jq, GPG key imported

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SECRETS_FILE="$REPO_DIR/modules/secrets/secret.yml"
PI_DIR="$HOME/.pi/agent"

echo "Decrypting secrets..."
outline_key=$(sops -d --extract '["outline_api_key"]' "$SECRETS_FILE")
linear_key=$(sops -d --extract '["linear_api_key"]' "$SECRETS_FILE")

# Create Pi directories
mkdir -p "$PI_DIR/mcp-oauth/linear"

# Write mcp.json with secrets injected
echo "Writing $PI_DIR/mcp.json..."
cat > "$PI_DIR/mcp.json" << EOF
{
  "settings": {
    "idleTimeout": 0,
    "directTools": false
  },
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "agent",
        "--project-from-cwd",
        "--open-web-dashboard",
        "false"
      ],
      "lifecycle": "eager",
      "directTools": [
        "read_file",
        "list_dir",
        "find_file",
        "search_for_pattern",
        "get_symbols_overview",
        "find_symbol",
        "find_referencing_symbols",
        "write_memory",
        "read_memory",
        "list_memories",
        "delete_memory",
        "edit_memory",
        "activate_project",
        "get_current_config",
        "onboarding"
      ]
    },
    "forgetful": {
      "command": "uvx",
      "args": [
        "forgetful-ai"
      ],
      "lifecycle": "eager"
    },
    "context7": {
      "command": "npx",
      "args": [
        "-y",
        "@upstash/context7-mcp"
      ],
      "lifecycle": "lazy",
      "directTools": true
    },
    "linear": {
      "url": "https://mcp.linear.app/sse",
      "auth": "oauth",
      "lifecycle": "lazy",
      "directTools": true
    },
    "outline": {
      "command": "npx",
      "args": [
        "-y",
        "--package=outline-mcp-server@latest",
        "-c",
        "outline-mcp-server-stdio"
      ],
      "env": {
        "OUTLINE_API_KEY": "${outline_key}",
        "OUTLINE_API_URL": "https://app.getoutline.com/api"
      },
      "lifecycle": "lazy",
      "directTools": true
    }
  }
}
EOF

# Write Linear OAuth tokens
echo "Writing $PI_DIR/mcp-oauth/linear/tokens.json..."
cat > "$PI_DIR/mcp-oauth/linear/tokens.json" << EOF
{
  "access_token": "${linear_key}",
  "token_type": "bearer"
}
EOF
chmod 600 "$PI_DIR/mcp-oauth/linear/tokens.json"

# Write settings.json
echo "Writing $PI_DIR/settings.json..."
cat > "$PI_DIR/settings.json" << 'EOF'
{
  "lastChangelogVersion": "0.52.10",
  "defaultProvider": "anthropic",
  "defaultModel": "claude-opus-4-6",
  "packages": [
    "npm:pi-mcp-adapter",
    "npm:pi-subagents",
    "npm:pi-powerline-footer",
    "npm:shitty-extensions",
    "npm:@aliou/pi-guardrails",
    "npm:@tmustier/pi-files-widget",
    "npm:pi-notify",
    "npm:pi-super-curl",
    "npm:@tmustier/pi-agent-teams",
    "npm:pi-prompt-template-model"
  ],
  "steeringMode": "one-at-a-time",
  "defaultThinkingLevel": "high",
  "showHardwareCursor": true,
  "theme": "dark"
}
EOF

# Copy agents, prompts, skills, extensions from repo
PI_ASSETS="$REPO_DIR/pi"

echo "Copying SYSTEM.md..."
cp "$PI_ASSETS/SYSTEM.md" "$PI_DIR/"

echo "Copying agents..."
mkdir -p "$PI_DIR/agents"
cp "$PI_ASSETS"/agents/*.md "$PI_DIR/agents/"
cp "$PI_ASSETS/AGENTS.md" "$PI_DIR/"

echo "Copying prompts..."
mkdir -p "$PI_DIR/prompts"
cp "$PI_ASSETS"/prompts/*.md "$PI_DIR/prompts/"

echo "Copying skills..."
mkdir -p "$PI_DIR/skills"
cp -r "$PI_ASSETS"/skills/* "$PI_DIR/skills/"

echo "Copying extensions..."
mkdir -p "$PI_DIR/extensions"
cp "$PI_ASSETS"/extensions/*.ts "$PI_DIR/extensions/"
cp -r "$PI_ASSETS/extensions/damage-control" "$PI_DIR/extensions/"
if [ -f "$PI_DIR/extensions/damage-control/package.json" ]; then
  echo "Installing damage-control dependencies..."
  (cd "$PI_DIR/extensions/damage-control" && npm install)
fi

echo "Done. Pi config written to $PI_DIR"
echo "Note: auth.json (Anthropic OAuth) must be created by running 'pi' and logging in."
