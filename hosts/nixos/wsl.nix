{ pkgs, inputs, ... }: {
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  wsl.enable = true;
  wsl.defaultUser = "reyhan";
  wsl.docker-desktop.enable = true;
  wsl.wslConf.network.generateHosts = false;
  wsl.wslConf.automount.options = "metadata,uid=1000,gid=100,umask=77,fmask=11";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nix.settings = {
    nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
    experimental-features = [ "flakes" "nix-command" ];
  };
  nixpkgs.config = { allowUnfree = true; };
  nixpkgs.overlays = [ ];

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;

  # environment.systemPackages = with pkgs; [ ];
  environment.shells = with pkgs; [ zsh ];
  environment.variables = { VAGRANT_WSL_ENABLE_WINDOWS_ACCESS = "1"; };

  networking.extraHosts = "192.168.0.157 ubuntu.local";

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
  ];
}

