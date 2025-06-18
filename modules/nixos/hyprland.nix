{ pkgs, config, ... }: {
  programs.hyprland = {
    enable = true;

    # set the flake package
    package = pkgs.hyprland;

    # make sure to also set the portal package, so that they are in sync
    portalPackage = pkgs.xdg-desktop-portal-hyprland;

    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    lshw
    kitty
    ghostty
    alsa-utils
    morewaita-icon-theme
    adwaita-icon-theme
    qogir-icon-theme
    loupe
    nautilus
    baobab
    gnome-text-editor
    gnome-calendar
    gnome-boxes
    gnome-system-monitor
    gnome-control-center
    gnome-weather
    gnome-calculator
    gnome-clocks
    gnome-software # for flatpak
    wl-clipboard
    wl-gammactl
    gnomeExtensions.just-perfection
  ];
  environment.gnome.excludePackages = with pkgs; [
    gnome-text-editor
    gnome-console
    gnome-photos
    gnome-tour
    gnome-connections
    snapshot
    gedit
    cheese # webcam tool
    epiphany # web browser
    geary # email reader
    evince # document viewer
    totem # video player
    yelp # Help view
    gnome-font-viewer
    gnome-shell-extensions
    gnome-maps
    gnome-music
    gnome-characters
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    gnome-contacts
    gnome-initial-setup
  ];
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # programs.dconf.enable = true;
  # programs.dconf.profiles.gdm.databases = [{
  #   settings = {
  #     "org/gnome/desktop/peripherals/touchpad" = { tap-to-click = true; };
  #     "org/gnome/desktop/interface" = { cursor-theme = "Qogir"; };
  #   };
  # }];
  # services.xserver.displayManager.startx.enable = true;

  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  security = {
    polkit.enable = true;
    pam.services.astal-auth = { };
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart =
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  services = {
    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    accounts-daemon.enable = true;
    gnome = {
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      localsearch.enable = true;
      tinysparql.enable = true;
    };
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command =
        "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --time --cmd Hyprland";
    };
  };

  systemd.tmpfiles.rules = [ "d '/var/cache/greeter' - greeter greeter - -" ];

  services.asusd = {
    enable = true;
    enableUserService = true;
  };

  # nvidia
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # openrgb
  services.hardware.openrgb.enable = true;

  # nvidia
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    modesetting.enable = true;

    powerManagement = {
      enable = true;
      finegrained = true;
    };

    open = true;
    nvidiaSettings = false; # gui app
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
}

