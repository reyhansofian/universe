# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS and Home Manager configuration repository ("universe") that manages:
- NixOS system configurations for desktop (Hyprland) and WSL environments
- Home Manager user configurations
- Custom Neovim configuration via nixvim
- Secret management with SOPS and GPG

## Architecture

### Flake Structure

The repository uses `flake-parts` and `ez-configs` for modular organization:

- **Root flake.nix**: Main entry point that imports all modules and defines outputs
  - Uses `ez-configs` to auto-discover host and module configurations
  - Defines custom overlays for package compatibility (ansible-language-server stub, fcitx5-with-addons)
  - Provides multi-branch nixpkgs access via `branches` overlay (master, stable, stable-24, unstable)
  - Exports `icons`, `colors`, and `color` flake attributes for theming

### Directory Organization

```
.
├── flake.nix                    # Main flake configuration
├── hosts/
│   ├── nixos/                   # NixOS system configurations
│   │   ├── desktop.nix          # Hyprland desktop (nixos-asus)
│   │   └── wsl.nix              # WSL2 environment
│   └── home-manager/
│       └── reyhan.nix           # User home configuration
├── modules/
│   ├── nixos/                   # System-level modules
│   │   ├── desktop-hardware.nix
│   │   ├── hyprland.nix
│   │   ├── dconf.nix
│   │   └── nautilus.nix
│   ├── home-manager/            # User-level modules
│   │   ├── packages.nix         # User packages
│   │   ├── programs.nix         # Program configurations
│   │   ├── shell.nix            # Zsh configuration
│   │   ├── git.nix
│   │   ├── tmux.nix
│   │   ├── hyprland.nix
│   │   ├── k8s.nix
│   │   └── ssh.nix
│   ├── nix/                     # Shared Nix infrastructure
│   │   ├── colors.nix           # Color scheme definitions
│   │   └── icons.nix            # Icon definitions
│   └── hyprland/                # Hyprland DE modules
└── nvim/                        # Nixvim configuration
    ├── default.nix              # Package definition
    └── config/
        ├── default.nix          # Import all config modules
        ├── lsp.nix              # Language server configuration
        ├── ai.nix               # AI/LLM integration
        ├── cmp.nix              # Completion configuration
        ├── editor.nix
        ├── keymap.nix
        ├── ui.nix
        └── plugins/             # Plugin-specific configs
```

### Key Architecture Patterns

1. **ez-configs Auto-Discovery**: The flake uses `ez-configs` to automatically discover:
   - NixOS hosts from `hosts/nixos/`
   - Home Manager users from `hosts/home-manager/`
   - NixOS modules from `modules/nixos/`
   - Home Manager modules from `modules/home-manager/`

2. **Host-Specific Logic**: Configurations conditionally enable features based on hostname:
   - `osConfig.networking.hostName == "nixos-asus"` for desktop-specific features (Hyprland, GUI apps)
   - WSL host uses minimal configuration without desktop environment

3. **Multi-Branch Package Access**: The `branches` overlay provides access to packages from different nixpkgs branches:
   ```nix
   pkgs.branches.master.<package>
   pkgs.branches.stable.<package>
   pkgs.branches.unstable.<package>
   ```

4. **Nixvim Integration**: Neovim configuration is:
   - Defined in `nvim/` directory using nixvim modules
   - Built as a flake package at `self.packages.${system}.nvim`
   - Imported into home-manager user packages

5. **Secret Management**: Uses SOPS-nix with GPG encryption:
   - Secrets stored in `modules/secrets/`
   - Configuration in `.sops.yml` with GPG key
   - Secrets injected at `~/.config/sops-nix/secrets/`

## Common Commands

### Building and Deploying

```bash
# Build NixOS configuration for current host
sudo nixos-rebuild switch --flake .

# Build for specific host
sudo nixos-rebuild switch --flake .#desktop
sudo nixos-rebuild switch --flake .#wsl

# Build home-manager configuration standalone
home-manager switch --flake .#reyhan

# Build without applying (dry-run)
nixos-rebuild build --flake .
```

### Development Workflow

```bash
# Format all Nix files (uses nixfmt-rfc-style)
nix fmt

# Check flake for errors
nix flake check

# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Build and test nvim package
nix build .#nvim
./result/bin/nvim

# Run nvim directly from flake
nix run .#nvim
```

### SOPS Secret Management

```bash
# Edit secrets file (requires GPG key)
sops modules/secrets/secret.yml

# Re-encrypt secrets after key changes
sops updatekeys modules/secrets/secret.yml

# Test secret decryption
systemctl --user status sops-nix
```

### Garbage Collection

```bash
# Clean old generations
sudo nix-collect-garbage --delete-older-than 7d

# Clean old home-manager generations
home-manager expire-generations "-7 days"
```

## Important Notes

### Package Management

- User packages defined in `modules/home-manager/packages.nix`
- System packages in host configs (`hosts/nixos/*.nix`)
- AI/LLM tools included: `opencode`, `gemini-cli`, `claude-code`
- Platform-specific packages use `lib.optionals pkgs.stdenv.isLinux` or `isDarwin`

### Neovim Configuration

- Uses nixvim for declarative Neovim configuration
- All plugins and LSP configs in Nix files under `nvim/config/`
- AI plugins configured: Avante, Copilot (in `nvim/config/ai.nix`)
- Custom Lua helpers available via `helpers.mkLuaFun` and `helpers.mkLuaFunWithName`
- To disable man page generation (ansible-language-server workaround): `enableMan = false`

### Desktop Environment

- Desktop host uses Hyprland with custom modules
- Hyprland config in `modules/hyprland/` and `modules/home-manager/hyprland.nix`
- WSL host has no desktop environment
- Screenshot tools: `hyprshot`, `grim`, `slurp`, `swappy`

### Shell Configuration

- Default shell: Zsh with Oh-My-Zsh
- Starship prompt configured in `modules/home-manager/programs.nix`
- Powerlevel10k theme available as fallback
- Shell aliases: `vim` → `nvim`, `k` → `kubectl`
- Direnv + nix-direnv enabled for automatic Nix shell activation

### Workarounds and Quirks

1. **ansible-language-server stub**: Dummy package overlay in flake.nix to fix nixvim compatibility
2. **fcitx5-with-addons location**: Overlay redirects from `libsForQt5` to `kdePackages`
3. **Docker socket permissions**: systemd service sets chmod 666 on desktop host
4. **SOPS re-activation**: WSL host has service to restart sops-nix after login

### Git Workflow

- Main branch: `main`
- Recent commits show feature additions and fixes
- Use conventional commit style based on repository history

<!-- AUTO-MANAGED SECTION - auto-memory will update below -->

## Auto-Managed Metadata

**Last Updated**: 2025-12-07
**Framework**: Nix Flake with flake-parts and ez-configs
**Total Nix Files**: 49
**Key Directories**: hosts/, modules/, nvim/

### Build/Deploy Commands
- `sudo nixos-rebuild switch --flake .`
- `home-manager switch --flake .#reyhan`
- `nix fmt` (format)
- `nix flake check` (validate)

### Key Files
- flake.nix: Root flake configuration
- nvim/: Neovim configuration via nixvim
- modules/: Modular system and home-manager configs
- hosts/: Host-specific configurations

<!-- END AUTO-MANAGED SECTION -->
