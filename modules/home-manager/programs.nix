{ pkgs, lib, ... }:
{
  programs = {
    home-manager.enable = true;
    fzf.enable = true;
    jq.enable = true;
    bat.enable = true;
    command-not-found.enable = true;
    dircolors.enable = true;
    htop.enable = true;
    info.enable = true;

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
      enableZshIntegration = true;
    };

    gpg = {
      enable = true;
      settings = {
        use-agent = true;
      };
    };
  };
}
