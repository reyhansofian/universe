{ lib, config, pkgs, ... }:

with lib;

let cfg = config.home.user-info.within.gpg;
in {
  options.within.gpg.enable = mkEnableOption "Enables Within's gpg config";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gnupg ];

    programs.gpg = {
      enable = cfg.enable;
      settings = { use-agent = true; };
    };

    home.file = {
      ".gnupg/gpg-agent.conf".source = pkgs.writeTextFile {
        name = "home-gpg-agent.conf";
        text = if pkgs.stdenv.isDarwin then
        # toml
        ''
          pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
        '' else
        # toml
        ''
          pinentry-program ${pkgs.pinentry}/bin/pinentry
        '';
      };
    };

  };
}
