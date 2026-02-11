{ pkgs, config, ezModules, self, inputs, lib, osConfig, ... }: {
  imports = with ezModules;
    [
      fonts
      k8s
      packages
      shell
      fish
      ssh
      programs
      tmux
      wezterm
      inputs.sops.homeManagerModules.sops
    ] ++ lib.optionals (osConfig.networking.hostName == "nixos-asus")
    [ hyprland ];

  home = {
    username = "reyhan";
    packages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.nvim
      self.packages.${pkgs.stdenv.hostPlatform.system}.ralph-claude-code
      self.packages.${pkgs.stdenv.hostPlatform.system}.fix-serena-config
      pkgs.sops
      inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.comma
      pkgs.inetutils
    ] ++ lib.optionals (osConfig.networking.hostName == "nixos-asus") [
      pkgs._1password-cli
      pkgs._1password-gui
      pkgs.hyprshot
      pkgs.fnott
    ];
    stateVersion = "25.05";
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.cache/npm/global/bin"
    ];
    homeDirectory = "/home/reyhan";
  };

  sops.gnupg.home = "~/.gnupg";
  sops.gnupg.sshKeyPaths = [ ];
  sops.defaultSopsFile = "${self}/modules/secrets/secret.yml";

  # Manually maps the key you need from your sops' secret file.
  sops.secrets = {
    open_api_key = { };
    anthropic_api_key = { };
  };

  services = {
    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-tty;
    };
  } // lib.optionalAttrs (osConfig.networking.hostName == "nixos-asus") {
    blueman-applet.enable = true;
  };

  systemd.user.services = {
    docker-socket = lib.optionalAttrs (osConfig.networking.hostName == "nixos-asus") {
      Unit = {
        Description = "Docker Socket";
        After = [ "docker.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/chmod 666 /var/run/docker.sock";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    rerun-sops-nix = lib.optionalAttrs (osConfig.networking.hostName != "nixos-asus") {
      Unit = {
        Description = "sops-nix re-activation";
        After = "sops-nix.service";
        Requires = "gpg-agent.service";
      };
      Install = { WantedBy = [ "default.target" "multi-user.target" ]; };
      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.lib.getExe pkgs.bash} -c "systemctl restart --user sops-nix.service"
        '';
      };
    };
  };
}
