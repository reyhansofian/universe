{ pkgs, ... }: {
  # Fix for Serena MCP language servers on NixOS
  # Serena downloads pre-built binaries that don't work on NixOS due to dynamic linking
  # This creates wrapper scripts that delegate to Nix-installed language servers

  home.activation.serenaLspFix = pkgs.lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create Serena language server directories
    $DRY_RUN_CMD mkdir -p $HOME/.serena/language_servers/static/Marksman

    # Create wrapper script for marksman
    $DRY_RUN_CMD cat > $HOME/.serena/language_servers/static/Marksman/marksman << 'EOF'
#!/usr/bin/env bash
exec ${pkgs.marksman}/bin/marksman "$@"
EOF

    $DRY_RUN_CMD chmod +x $HOME/.serena/language_servers/static/Marksman/marksman
  '';
}
