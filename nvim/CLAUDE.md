# nvim/ - Nixvim Configuration

This directory contains a declarative Neovim configuration using nixvim, built as a flake package.

## Overview

This nixvim configuration provides:
- Comprehensive LSP setup with 20+ language servers
- AI/LLM integration (Claude Code, Avante, optional Copilot)
- Advanced completion with nvim-cmp
- Modern UI with neo-tree, telescope, and treesitter
- Custom Lua helpers for function generation

## Architecture

### Package Structure

The nvim package is defined in `default.nix` and built via flake-parts:
- Imports configuration from `config/default.nix`
- Provides custom `helpers` (mkLuaFun, mkLuaFunWithName)
- Passes special args: `icons`, `branches`, `helpers`, `system`, `self`
- Disables man page generation (`enableMan = false`) to avoid ansible-language-server errors

### Configuration Modules

All configuration is in `config/`:
- **lsp.nix**: Language server configurations, inlay hints
- **ai.nix**: AI plugins (Claude Code, Avante, Neotest)
- **cmp.nix**: Completion configuration
- **keymap.nix**: Keybindings
- **ui.nix**: UI plugins and settings
- **editor.nix**: Editor behavior
- **global.nix**: Global options
- **autocmd.nix**: Auto commands
- **secret.nix**: SOPS-encrypted secrets

Plugin-specific configs in `config/plugins/`:
- avante.nix, comment.nix, git.nix, markview.nix
- neo-tree.nix, telescope.nix, toggleterm.nix, treesitter.nix

## Key Features

### AI Integration

Enabled plugins:
- **claude-code**: Claude Code integration
- **avante**: AI-powered editing (`<leader>aa`, `<leader>ac`, `<leader>ae`)
- **neotest**: Testing framework with plenary adapter

Disabled/optional:
- copilot-lua (commented out)
- windsurf-nvim (commented out)
- codeium-nvim (commented out, uses SOPS secret)

### LSP Configuration

Language servers configured in `lsp.nix`:
- Nix: nil, nixd
- TypeScript/JavaScript: typescript-language-server, vtsls
- Python: pyright, ruff
- Go: gopls
- Rust: rust-analyzer
- And 15+ more languages

Features:
- Inlay hints (toggle with `:LspInlay`)
- Highlight customization for hints
- Extra packages: nixfmt-classic, manix

### Completion

nvim-cmp configured with sources:
- LSP
- Buffer
- Path
- Luasnip
- Optional AI sources (copilot, windsurf)

### Custom Lua Helpers

Available via `helpers` special arg:
```nix
helpers.mkLuaFun "code"           # Returns: function() code end
helpers.mkLuaFunWithName "name" "code"  # Returns: function name() code end
```

Used for defining callbacks and commands inline.

## Build Commands

```bash
# Build nvim package
nix build .#nvim

# Run nvim directly
nix run .#nvim

# Test nvim without building
./result/bin/nvim

# Check nvim configuration
nix flake check .  # Runs nvimCheck derivation
```

## Common Patterns

### Adding a Plugin

1. Add plugin config in `config/plugins/plugin-name.nix`
2. Import in `config/default.nix`
3. Configure with nixvim options: `plugins.plugin-name.enable = true`

### Adding an LSP Server

In `lsp.nix`:
```nix
plugins.lsp.servers.language-name.enable = true;
```

Add language server package to `extraPackages` if needed.

### Adding Keybindings

Use `plugins.which-key.settings.spec` in relevant config file:
```nix
{
  __unkeyed-1 = "<leader>xy";
  __unkeyed-2 = "<cmd>SomeCommand<cr>";
  icon = icons.someIcon;
  desc = "Description";
}
```

### Using SOPS Secrets

Reference encrypted values:
```nix
config_path.__raw = ''vim.env.HOME .. '/.config/sops-nix/secrets/secret-name' '';
```

## Important Notes

- **Man pages disabled**: `enableMan = false` works around ansible-language-server build issue
- **Icons access**: Use `icons` special arg (defined in root flake)
- **Multi-branch packages**: Access via `branches.stable.*`, `branches.unstable.*`
- **Lua inline**: Prefer `__raw` for Lua code; use helpers for functions
- **CMP in neorepl**: Completion disabled in neorepl buffers (autocmd in ai.nix)

## Testing

The flake provides a check derivation:
```bash
nix flake check .  # Runs nixvim checks
```

This validates the configuration without building the full package.

<!-- AUTO-MANAGED SECTION - auto-memory will update below -->

## Auto-Managed Metadata

**Last Updated**: 2025-12-07
**Total Files**: 24 Nix files
**Primary Modules**: lsp.nix (LSP), ai.nix (AI plugins), cmp.nix (completion)

### Key Files Changed Recently
- config/lsp.nix: LSP and language server setup
- config/ai.nix: AI plugin configuration
- plugins/avante.nix: Avante AI plugin settings

### Active Plugins
- LSP: 20+ language servers
- AI: claude-code, avante, neotest
- UI: neo-tree, telescope, treesitter
- Git: git.nix plugins

<!-- END AUTO-MANAGED SECTION -->
