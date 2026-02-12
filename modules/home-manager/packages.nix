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
      branches.master.bun
      devenv
      cmake

      # Git
      gh
      git-crypt
      git-lfs
      git
      yadm
      jujutsu
      inputs.self.packages.${pkgs.system}.tuicr

      # AI/LLM Tools
      opencode
      gemini-cli
      uv # Required for Serena MCP
      inputs.self.packages.${pkgs.system}.beads # Distributed git-backed graph issue tracker for AI agents
      inputs.self.packages.${pkgs.system}.beads-viewer # TUI for visualizing Beads task dependencies
      inputs.self.packages.${pkgs.system}.codanna # Code intelligence for AI assistants
      inputs.self.packages.${pkgs.system}.omp # Oh-my-pi: batteries-included AI coding agent

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
