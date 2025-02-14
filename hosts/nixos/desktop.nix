{ nixpkgs, pkgs, inputs, modulesPath, self, ... }: {
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

  users.extraUsers = {
    root = { hashedPassword = "*"; };

    reyhan = {
      isNormalUser = true;
      uid = 1000;
      extraGroups =
        [ "wheel" "networkmanager" "wireshark" "docker" "kvm" "vboxusers" ];
      useDefaultShell = true;

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

  # environment.systemPackages = pkgs;
  environment.shells = with pkgs; [ zsh ];

  networking.extraHosts = "192.168.0.157 ubuntu.local";

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
  ];

  nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; }; # this is the important part
    modules = [ "${self}/modules/hyprland" ];
  };
}
