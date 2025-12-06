{ pkgs, inputs, self, ... }: {
  nixpkgs = { inherit (self.nixpkgs) config overlays; };

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

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nix.settings = {
    nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
    experimental-features = [ "flakes" "nix-command" ];
  };

  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;

  services.dbus.enable = true;

  # environment.systemPackages = [ inputs.nixpkgs-master.claude-code ];
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

