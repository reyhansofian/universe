{ pkgs, inputs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/all-hardware.nix"
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nix.settings = {
    nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
    experimental-features = [ "flakes" "nix-command" ];
  };
  # users.users.reyhan.group = "reyhan";
  #  users.groups.reyhan = {};
  #  users.users.reyhan.isNormalUser = true;
  #  users.users.reyhan.initialHashedPassword = "nixos";

  users.extraUsers = {
    root = { hashedPassword = "*"; };

    reyhan = {
      isNormalUser = true;
      uid = 1000;
      extraGroups =
        [ "wheel" "networkmanager" "wireshark" "docker" "kvm" "vboxusers" ];
      useDefaultShell = true;
      # openssh.authorizedKeys.keys = keys.jtojnar;

      # generated using `mkpasswd --method=sha-512`
      hashedPassword =
        "$6$KmjOnrNHWtJrJgiF$f18JDyaKXtMFaaZ6NVizL7V3qb76XzWkZqCfXBJ9rQAExmNQsF1yiCbmUanSajj9moucqmrfBBOpQiyY5Z7Sp1";
    };
  };
  users.defaultUserShell = pkgs.zsh;

  nixpkgs.config = { allowUnfree = true; };
  nixpkgs.overlays = [ ];

  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;

  programs.hyprland.enable = true;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [ ];
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
