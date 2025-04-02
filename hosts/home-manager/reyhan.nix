{ pkgs, ezModules, self, inputs, lib, osConfig, ... }: {
  imports = with ezModules;
    [
      fonts
      k8s
      packages
      shell
      ssh
      programs
      tmux
      inputs.sops.homeManagerModules.sops
    ] ++ lib.optionals (osConfig.networking.hostName == "nixos-asus")
    [ hyprland ];

  home = {
    username = "reyhan";
    packages = [
      self.packages.${pkgs.stdenv.system}.nvim
      pkgs.sops
      pkgs.branches.master.claude-code
    ];
    stateVersion = "25.05";
    sessionPath = [ "~/.local/bin" ];
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
      pinentryPackage = pkgs.pinentry-tty;
    };
  };

  # systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
  systemd.user.services.rerun-sops-nix = {
    Unit = {
      Description = "sops-nix re-activation";
      After = "sops-nix.service";
      Requires = "gpg-agent.service";
    };

    Install = { WantedBy = [ "default.target" "multi-user.target" ]; };

    Service = {
      Type = "oneshot";
      ExecStart = ''
        ${
          pkgs.lib.getExe pkgs.bash
        } -c "systemctl restart --user sops-nix.service"
      '';
    };
  };
}
