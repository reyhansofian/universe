{ pkgs, config, lib, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    oh-my-zsh.enable = true;
    oh-my-zsh.plugins = [ "git" "ssh-agent" ];
    oh-my-zsh.theme = "robbyrussell";

    initExtraBeforeCompInit = ''
      # p10k instant prompt
      P10K_INSTANT_PROMPT="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"
      [[ ! -r "$P10K_INSTANT_PROMPT" ]] || source "$P10K_INSTANT_PROMPT"
    '';

    loginExtra = ''
      export ANTHROPIC_API_KEY="$(<"/home/reyhan/.config/sops-nix/secrets/anthropic_api_key")"
      export OPENAI_API_KEY="$(<"/home/reyhan/.config/sops-nix/secrets/open_api_key")"
    '';

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.5.0";
          sha256 = "0za4aiwwrlawnia4f29msk822rj9bgcygw6a8a6iikiwzjjz0g91";
        };
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./config/zsh/plugins/p10k;
        file = "p10k.zsh";
      }
    ];

    shellAliases = {
      l = "ls -CF";
      ll = "ls -alF";
      la = "ls -A";
      vim = "nvim";
      vi = "nvim";
      py = "python";
      k = "kubectl";
    };

    initExtra = ''
      bindkey "^[[1;5D" backward-word
      bindkey "^[[1;5C" forward-word

      ZSH_AUTOSUGGEST_STRATEGY=(completion history)
      export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
      export PATH="$PATH:/mnt/e/VirtualBox"
    '';
  };
}
