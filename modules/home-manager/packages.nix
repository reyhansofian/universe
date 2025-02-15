{ pkgs, lib, ... }: {
  home.packages = with pkgs;
    [
      # System
      docker
      asciinema
      tldr
      procs
      tree
      ripgrep
      file
      binutils
      fd
      highlight
      openssh
      zsh
      gnumake42
      dnsutils
      openssl
      jq

      # Git
      gitAndTools.gh
      git-crypt
      git-lfs
      git

      unzip
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
      # Add packages only for Darwin (MacOS)
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      # Add packages only for Linux
      xclip
    ];
}
