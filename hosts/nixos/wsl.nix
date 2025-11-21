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
  environment.shells = with pkgs; [ zsh ];
  environment.systemPackages = with pkgs; [ iproute2 ];
  # environment.variables = { VAGRANT_WSL_ENABLE_WINDOWS_ACCESS = "1"; };

  # Add VPN routes for AWS internal IPs
  systemd.services.wsl-vpn-routes = {
    description = "Add VPN routes for AWS access";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Get the Windows host IP (default gateway)
      GATEWAY=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk '{print $3}')

      # Add routes for common AWS VPC CIDR blocks
      ${pkgs.iproute2}/bin/ip route add 10.0.0.0/8 via $GATEWAY 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip route add 172.16.0.0/12 via $GATEWAY 2>/dev/null || true

      echo "VPN routes added via gateway $GATEWAY"
    '';
  };

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

