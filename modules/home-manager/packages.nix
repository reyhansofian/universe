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
      lsd
      jump
      nodejs

      # Git
      gh
      git-crypt
      git-lfs
      git
      yadm

      # AI/LLM Tools
      opencode
      gemini-cli
      uv  # Required for Serena MCP

      unzip
      kittysay
      starship
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
      # Add packages only for Darwin (MacOS)
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      # Add packages only for Linux
      xclip
      bruno

      openvpn
      networkmanager-openvpn

      redis
    ];
}
