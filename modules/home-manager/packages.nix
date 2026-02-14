{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # System
      docker
      asciinema
      tldr
      procs
      tree
      ripgrep
      delta
      glow
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
      sqlite
      jump
      nodejs
      pkgs.branches.master.bun
      devenv
      cmake

      # Git
      gh
      git-crypt
      git-lfs
      git
      yadm
      jujutsu
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.jj-ws
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.tuicr

      # AI/LLM Tools
      opencode
      gemini-cli
      uv # Required for Serena MCP
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.beads # Distributed git-backed graph issue tracker for AI agents
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.beads-viewer # TUI for visualizing Beads task dependencies

      # Language Servers for Serena MCP
      marksman # Markdown LSP
      nil # Nix LSP
      typescript-language-server # TypeScript/JavaScript LSP
      bash-language-server # Bash LSP
      terraform # Terraform CLI and LSP support
      terraform-ls # Terraform Language Server

      unzip
      kittysay
      starship

      (lib.lowPrio python311)
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # Add packages only for Darwin (MacOS)
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Add packages only for Linux
      xclip
      bruno

      openvpn
      networkmanager-openvpn

      redis
    ];
}
