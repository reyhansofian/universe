{ pkgs, ezModules, self, inputs, config, lib, ... }: {
  imports = with ezModules; [
    fonts
    k8s
    packages
    shell
    ssh
    programs
    inputs.sops.homeManagerModules.sops
  ];

  home = {
    username = "reyhan";
    packages = [ self.packages.${pkgs.stdenv.system}.nvim pkgs.sops ];
    stateVersion = "25.05";
    sessionPath = [ "~/.local/bin" ];
    homeDirectory = "/home/reyhan";
    sessionVariables.OPENAI_API_KEY = # bash
      ''$(<"${config.sops.secrets.open_api_key.path}")'';
    sessionVariables.ANTHROPIC_API_KEY = # bash
      ''$(<"${config.sops.secrets.anthropic_api_key.path}")'';
  };

  sops.gnupg.home = "~/.gnupg";
  sops.gnupg.sshKeyPaths = [ ];
  sops.defaultSopsFile = "${self}/modules/secrets/secret.yml";
  sops.secrets.open_api_key = { };
  sops.secrets.anthropic_api_key = { };
  # sops.secrets.codeium.path = "%r/codeium";
  # sops.secrets."${self}/modules/secrets/secret.yml" = {
  #   restartUnits = [ "home-manager-reyhan.service" ];
  #   # there is also `reloadUnits` which acts like a `reloadTrigger` in a NixOS systemd service
  # };

  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
  services = {
    gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
  systemd.user.services.rerun-sops-nix = {
    Unit = {
      Description = "sops-nix re-activation";
      After = "sops-nix.service";
      Requires = "gpg-agent.service";
    };

    Install = { WantedBy = [ "default.target" "multi-user.target" ]; };

    Service = {
      ExecStart = ''
        ${
          pkgs.lib.getExe pkgs.bash
        } -c "systemctl restart --user sops-nix.service"
      '';
    };
  };
}
