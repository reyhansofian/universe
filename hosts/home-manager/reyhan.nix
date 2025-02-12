{ pkgs, ezModules, self, ... }: {
  imports = with ezModules; [ fonts k8s packages shell ssh programs ];

  home = {
    packages = [ self.packages.${pkgs.stdenv.system}.nvim ];
    stateVersion = "25.05";
    sessionPath = [ "~/.local/bin" ];
  };

  services = {
    gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
}

