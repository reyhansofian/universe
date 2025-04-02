{
  programs.git.enable = true;
  programs.git.extraConfig.diff.sopsdiffer.textconv =
    "sops -d --config /dev/null";
}
