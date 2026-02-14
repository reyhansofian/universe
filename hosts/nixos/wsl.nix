{ pkgs, inputs, self, ... }: {
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
    tarball-ttl = 0;
    contentAddressedByDefault = false;
  };
  nixpkgs.overlays = builtins.attrValues self.overlays;

  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.home-manager.nixosModules.default
  ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  wsl.enable = true;
  wsl.defaultUser = "reyhan";
  wsl.docker-desktop.enable = true;
  wsl.wslConf.network.generateHosts = false;
  wsl.wslConf.automount.options = "metadata,uid=1000,gid=100";

  # GPU support for WSL2
  hardware.graphics.enable = true;
  wsl.useWindowsDriver = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nix.settings = {
    nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
    experimental-features = [ "flakes" "nix-command" ];
    trusted-users = [ "root" "reyhan" "@wheel" ];
  };

  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;

  services.dbus.enable = true;
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "16384";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NEW_ENGINE = "1";
    };
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glibc
    zlib
  ];

  environment.systemPackages = with pkgs; [
    mesa-demos    # provides glxinfo
    vulkan-tools  # provides vulkaninfo
    # Build tools for npm native modules
    gcc
    gnumake
    cmake
  ];
  environment.sessionVariables.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  environment.shells = with pkgs; [ fish zsh ];
  # environment.variables = { VAGRANT_WSL_ENABLE_WINDOWS_ACCESS = "1"; };

  networking.hostName = "nixos";
  networking.extraHosts = "192.168.0.157 ubuntu.local";

  users.users.reyhan = {
    shell = pkgs.fish;
    home = "/home/reyhan";
  };
  programs.fish.enable = true;
  programs.zsh.enable = true;

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
  ];
}

