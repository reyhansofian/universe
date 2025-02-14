{ pkgs, inputs, ... }: {
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
  # wsl.wslConf.boot.command = ''
  #   systemctl restart --user sops-nix.service
  # '';

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

  services.dbus.enable = true;

  # environment.systemPackages = with pkgs; [ ];
  environment.shells = with pkgs; [ zsh ];
  # environment.variables = { VAGRANT_WSL_ENABLE_WINDOWS_ACCESS = "1"; };

  networking.hostName = "nixos";
  networking.extraHosts = "192.168.0.157 ubuntu.local";

  users.users.reyhan = {
    shell = pkgs.zsh;
    home = "/home/reyhan";
  };
  programs.zsh.enable = true;

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
  ];
}

