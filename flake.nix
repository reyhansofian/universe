{
  description = "NixOS + standalone home-manager config flakes to get you started!";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.follows = "nixpkgs-unstable"; 
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

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
    nixvim.inputs.nix-darwin.follows = "nix-darwin";
    nixvim.inputs.home-manager.follows = "home-manager";
    nixvim.inputs.flake-parts.follows = "flake-parts";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, self,... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    flake = {
      # Put your original flake attributes here.
    };

    imports = [
      inputs.ez-configs.flakeModule
      ./modules/nix
      ./nvim
    ];

    ezConfigs = {
      root = ./.;
      globalArgs = { 
        inherit inputs self; 
        # inherit (self) packages;
      };
      home.configurationsDirectory = ./hosts/home-manager;
      home.modulesDirectory = ./modules/home-manager;

      nixos.configurationsDirectory = ./hosts/nixos;
      nixos.hosts = {
        desktop = {
          userHomeModules = [ "reyhan" ];
        };

        wsl = {
          userHomeModules = [ "reyhan" ];
        };
      };

      darwin.configurationsDirectory = ./hosts/darwin;
    };

    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    perSystem = { config, system, lib, inputs', ... }: {
      formatter = inputs'.nixpkgs.nixfmt-rfc-style;
      _module.args =
        let
          overlays = [
            # inputs.ocaml-overlay.overlays.default
          ] ++ lib.attrValues self.overlays;
          icons = import ./icons.nix;
          colors = import ./colors.nix { inherit lib; };
          color = colors.mkColor colors.lists.edge;
        in
        rec {
          inherit icons colors color;
          # the nix package manager configurations and settings.
          nix =
            import ./nix.nix {
              inherit lib inputs inputs';
              inherit (pkgs) stdenv;
            }
            // {
              package = branches.master.nix;
            };

          pkgs = import inputs.nixpkgs {
            inherit system;
            inherit (nixpkgs) config;
            inherit overlays;
          };

          # nixpkgs (channel) configuration (not the flake input)
          nixpkgs = {
            config = lib.mkForce {
              allowBroken = true;
              allowUnfree = true;
              tarball-ttl = 0;

              # Experimental options, disable if you don't know what you are doing!
              contentAddressedByDefault = false;
            };

            hostPlatform = system;

            overlays = lib.mkForce overlays;
          };

          /*
            One can access these nixpkgs branches like so:

            `branches.stable.mpd'
            `branches.master.linuxPackages_xanmod'
          */
          branches =
            let
              pkgsFrom =
                branch: system:
                import branch {
                  inherit system;
                  inherit (nixpkgs) config;
                };
            in
            {
              master = pkgsFrom inputs.nixpkgs-master system;
              stable = pkgsFrom inputs.nixpkgs-stable system;
              unstable = pkgsFrom inputs.nixpkgs-unstable system;
            };

          /*
            Extra arguments passed to the module system for:

            `nix-darwin`
            `NixOS`
            `home-manager`
          */
          extraModuleArgs = {
            inherit
              inputs'
              system
              branches
              colors
              color
              icons
              ;
            inputs = lib.mkForce inputs;
          };

          # NixOS and nix-darwin base environment.systemPackages
          basePackagesFor =
            pkgs:
            builtins.attrValues {
              inherit (pkgs)
                vim
                curl
                fd
                wget
                git
                ;

              home-manager = inputs'.home-manager.packages.home-manager.override {
                path = "${inputs.home-manager}";
              };
            };
        };
      };
    };
}
