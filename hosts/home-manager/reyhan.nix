{ pkgs, ezModules, self, inputs, config, ... }: {
  imports = with ezModules; [
    fonts
    k8s
    packages
    shell
    ssh
    programs
    inputs.sops.homeManagerModules.sops
  ];

  sops.gnupg.home = "~/.gnupg";
  sops.gnupg.sshKeyPaths = [ ];
  sops.defaultSopsFile = "${self}/modules/secrets/secret.yml";
  sops.secrets.open_api_key = { };
  # sops.secrets.codeium.path = "%r/codeium";

  home = {
    username = "reyhan";
    packages = [ self.packages.${pkgs.stdenv.system}.nvim pkgs.sops ];
    stateVersion = "25.05";
    sessionPath = [ "~/.local/bin" ];
    homeDirectory = "/home/reyhan";
    sessionVariables.OPENAI_API_KEY = # bash
      ''$(<"${config.sops.secrets.open_api_key.path}")'';
  };

  services = {
    gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
}

