{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
	  nerd-fonts.fira-code
	  nerd-fonts.droid-sans-mono
	  nerd-fonts.hack
  ];
}
