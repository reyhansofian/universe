{
  description =
    "NixOS + standalone home-manager config flakes to get you started!";

  inputs = {
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/25.05-pre";
    nixpkgs-stable-24.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    ez-configs = {
      url = "github:ehllie/ez-configs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    ## Nixvim
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.inputs.flake-parts.follows = "flake-parts";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secret management
    sops.url = "github:Mic92/sops-nix";
    sops.inputs.nixpkgs.follows = "nixpkgs";

    # Desktop Environment using Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Claude Code - Auto-updated version with Cachix support
    claude-code-nix.url = "github:sadjow/claude-code-nix";

    # Ralph for Claude Code - Autonomous development loops
    ralph-claude-code = {
      url = "github:frankbria/ralph-claude-code";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      imports = [
        inputs.ez-configs.flakeModule
        ./modules/nix
        ./nvim
        ({ lib, ... }: {
          flake = {
            overlays.default = final: prev: {
              # Provide dummy ansible-language-server for nixvim compatibility
              # ansible-language-server was removed from nixpkgs but nixvim still references it
              ansible-language-server =
                final.runCommand "ansible-language-server-stub" {
                  meta.homepage = null;
                } "mkdir -p $out";

              # Fix fcitx5-with-addons location change for home-manager compatibility
              # fcitx5-with-addons was moved from libsForQt5 to kdePackages
              libsForQt5 = prev.libsForQt5 // {
                fcitx5-with-addons =
                  final.kdePackages.fcitx5-with-addons or (final.runCommand
                    "fcitx5-with-addons-stub" { } "mkdir -p $out");
              };

              branches = let
                pkgsFrom = branch: system:
                  import branch {
                    inherit system;
                    inherit (inputs.self.nixpkgs) config;
                  };
              in {
                master = pkgsFrom inputs.nixpkgs-master
                  prev.stdenv.hostPlatform.system;
                stable = pkgsFrom inputs.nixpkgs-stable
                  prev.stdenv.hostPlatform.system;
                stable-24 = pkgsFrom inputs.nixpkgs-stable-24
                  prev.stdenv.hostPlatform.system;
                unstable = pkgsFrom inputs.nixpkgs-unstable
                  prev.stdenv.hostPlatform.system;
              };
            };

            # Put your original flake attributes here.
            nixpkgs = {
              config = {
                allowBroken = true;
                allowUnfree = true;
                tarball-ttl = 0;

                # Experimental options, disable if you don't know what you are doing!
                contentAddressedByDefault = false;
              };

              overlays = [
                #   (final: prev: {
                #     vimPlugins = prev.vimPlugins.extend (_: p: {
                #       avante-nvim = p.avante-nvim.overrideAttrs (_: {
                #         src = prev.fetchFromGitHub {
                #           owner = "yetone";
                #           repo = "avante.nvim";
                #           rev = "d4e58f6a22ae424c9ade2146b29dc808a7e4c538";
                #           hash =
                #             "sha256-4fI2u3qZOFadyqMYDJOCgiWrT3aRKVTmEgg7FuZJgGo=";
                #         };
                #       });
                #     });
                #   })
              ] ++ lib.attrValues inputs.self.overlays;
            };

            icons = import ./modules/nix/icons.nix;
            colors = import ./modules/nix/colors.nix { inherit lib; };
            color = inputs.self.colors.mkColor inputs.self.colors.lists.edge;
          };
        })
        {
          perSystem = { system, inputs', pkgs, ... }: {
            formatter = inputs'.nixpkgs.legacyPackages.nixfmt-rfc-style;
            _module.args = {
              inherit (inputs.self) icons colors color;
              extraModuleArgs = { inherit (inputs.self) icons colors color; };

              pkgs = import inputs.nixpkgs {
                inherit system;
                inherit (inputs.self.nixpkgs) config overlays;
              };
            };

            packages.ralph-claude-code = pkgs.callPackage ./pkgs/ralph-claude-code {
              ralph-claude-code-src = inputs.ralph-claude-code;
            };

            packages.beads = pkgs.callPackage ./pkgs/beads { };
          };
        }
      ];

      ezConfigs = {
        root = ./.;
        globalArgs = {
          inherit inputs;
          inherit (inputs) self;
          inherit (inputs.self) icons colors color;
          # inherit (self) packages;
        };
        home.configurationsDirectory = ./hosts/home-manager;
        home.modulesDirectory = ./modules/home-manager;
        # home.users.reyhan.passInOsConfig = true;

        nixos.configurationsDirectory = ./hosts/nixos;
        nixos.modulesDirectory = ./modules/nixos;
        nixos.hosts = {
          desktop = { userHomeModules = [ "reyhan" ]; };
          wsl = { userHomeModules = [ "reyhan" ]; };
        };

        # darwin.configurationsDirectory = ./hosts/darwin;
      };

      systems = [ "x86_64-linux" "aarch64-linux" ];
    };
}
