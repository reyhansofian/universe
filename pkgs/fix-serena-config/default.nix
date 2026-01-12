{ writeShellScriptBin }:

writeShellScriptBin "fix-serena-config" ''
  # fix-serena-config: Ensures Serena MCP plugin has correct configuration
  # Run this after reinstalling the Serena plugin

  set -euo pipefail

  SERENA_CONFIG='{
    "serena": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "claude-code",
        "--project-from-cwd"
      ]
    }
  }'

  CACHE_DIR="$HOME/.claude/plugins/cache/claude-plugins-official/serena"
  MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/serena"

  updated=0

  # Update all cache directories
  if [[ -d "$CACHE_DIR" ]]; then
    for dir in "$CACHE_DIR"/*/; do
      if [[ -d "$dir" ]]; then
        echo "$SERENA_CONFIG" > "''${dir}.mcp.json"
        echo "Updated: ''${dir}.mcp.json"
        ((updated++)) || true
      fi
    done
  fi

  # Update marketplace source
  if [[ -d "$MARKETPLACE_DIR" ]]; then
    echo "$SERENA_CONFIG" > "$MARKETPLACE_DIR/.mcp.json"
    echo "Updated: $MARKETPLACE_DIR/.mcp.json"
    ((updated++)) || true
  fi

  if [[ $updated -eq 0 ]]; then
    echo "No Serena config files found. Is the plugin installed?"
    exit 1
  fi

  echo ""
  echo "Done. Updated $updated config file(s)."
  echo "Restart Claude Code to apply changes."
''
