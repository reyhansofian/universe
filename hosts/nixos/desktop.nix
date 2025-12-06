{ lib, pkgs, inputs, ezModules, ... }: {
  imports = with ezModules; [ desktop-hardware hyprland ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  # Enable the unfree 1Password packages
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "1password-gui" "1password" ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = ".backup-before-home-manager";

  nix.settings = {
    nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
    experimental-features = [ "flakes" "nix-command" ];
  };

  users.users = {
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
  users.defaultUserShell = pkgs.fish;

  nixpkgs.config = { allowUnfree = true; };
  nixpkgs.overlays = [ ];

  # Install firefox.
  programs.firefox.enable = true;

  # Install 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "computecoholic" ];
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      # Configure Docker to use overlay2 storage driver
      storage-driver = "overlay2";

      # Define default address pools for networks
      # default-address-pools = [
      #   {
      #     base = "172.16.0.0/16";
      #     size = 24;
      #   }
      #   {
      #     base = "172.17.0.0/16";
      #     size = 24;
      #   }
      # ];

      # Enable live restore
      live-restore = true;

      # Enable experimental features
      experimental = false;
    };
  };

  environment.systemPackages = with pkgs;
    [ google-chrome discord spotify networkmanagerapplet swappy slurp grim ]
    ++ (with pkgs.nixos-artwork.wallpapers; [ binary-black ]);
  environment.shells = with pkgs; [ fish zsh ];

  networking.hostName = "nixos-asus";
  networking.networkmanager.enable = true;
  networking.nameservers = [
    # Cloudflare
    "1.1.1.1"
    "1.0.0.1"
    # Google
    "8.8.8.8"
    "8.8.4.4"
  ];
  networking.firewall.allowedTCPPorts = [ 22 443 943 ];

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "yes";
    };
  };
  services.logind.lidSwitch = "suspend";

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable sound with pipewire.

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  # systemd.services."getty@tty1".enable = false;
  # systemd.services."autovt@tty1".enable = false;

  programs.fish.enable = true;
  programs.zsh.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
  services = {
    xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];

      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    sysprof.enable = true;
    printing.enable = true;
    flatpak.enable = true;
  };

  # XDG
  xdg.portal.enable = true;
  xdg.icons.enable = true;
  xdg.menus.enable = true;
  xdg.sounds.enable = true;

  systemd.services.battery-charge-threshold = {
    wantedBy = [ "local-fs.target" "suspend.target" ];
    after = [ "local-fs.target" "suspend.target" ];
    description = "Set the battery charge threshold to ${toString 100}%";
    startLimitBurst = 5;
    startLimitIntervalSec = 1;
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      ExecStart = "${pkgs.runtimeShell} -c 'echo ${
          toString 100
        } > /sys/class/power_supply/BAT?/charge_control_end_threshold'";
    };
  };

  # specialisation = {
  #   gnome.configuration = {
  #     system.nixos.tags = [ "Gnome" ];
  #     hyprland.enable = lib.mkForce false;
  #     gnome.enable = lib.mkForce true;
  #   };
  # };

}
