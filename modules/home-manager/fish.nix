{ pkgs, config, lib, ... }: {
  programs.fish = {
    enable = true;

    # Shell aliases (merged from matchai's dotfiles and existing config)
    shellAliases = {
      # App substitutions for better tools
      git = "${pkgs.git}/bin/git"; # Can be changed to hub if desired
      vim = "nvim";
      vi = "nvim";
      ls = "${pkgs.lsd}/bin/lsd";

      # File navigation
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";

      # Editor shortcuts
      py = "python";
      k = "kubectl";
      clauded = "claude --dangerously-skip-permissions";

      # Reload shell
      reload = "exec fish";

      # Tmux workspace aliases (migrated from tmux.nix)
      tpass = "tmuxp load ${
          builtins.toFile "tmuxp-paas.json" (builtins.toJSON {
            session_name = "PaaS";
            windows = [
              {
                window_name = "Code";
                layout = "tiled";
                shell_command_before = [ "cd ~/Projects/PaaS/monorepo-paas" ];
                panes = [ ''kittysay --think "Monorepo Code"'' ];
              }
              {
                window_name = "Clan.lol";
                layout = "even-vertical";
                shell_command_before = [ "cd ~/Projects/PaaS/clan/paas" ];
                panes = [
                  ''
                    kittysay --think "PaaS NixOS Deployment using Clan.lol - Code"''
                  ''
                    kittysay --think "PaaS NixOS Deployment using Clan.lol - Terminal"''
                ];
              }
            ];
          })
        }";
      tnoice = "tmuxp load ${
          builtins.toFile "tmuxp-noice.json" (builtins.toJSON {
            session_name = "Noice - Work";
            windows = [{
              window_name = "Noice - Work";
              layout = "tiled";
              shell_command_before = [ "cd ~/Projects/Noice" ];
              panes = [ ''kittysay --think "Happy working"'' ];
            }];
          })
        }";
      tmw = "tmuxp load ${
          builtins.toFile "tmuxp-work.json" (builtins.toJSON {
            session_name = "Work";
            windows = [{
              window_name = "Work";
              layout = "tiled";
              shell_command_before = [ "cd ~/Projects" ];
              panes = [ ''kittysay --think "Happy working"'' ];
            }];
          })
        }";
      tme = "tmuxp load ${
          builtins.toFile "tmuxp-me.json" (builtins.toJSON {
            session_name = "Me";
            windows = [{
              window_name = "Me";
              layout = "tiled";
              shell_command_before = [ "cd ~/.config/universe" ];
              panes = [ ''kittysay --think "Happy configuring NixOS"'' ];
            }];
          })
        }";
    };

    # Fish abbreviations (Fish-specific feature for command expansion)
    shellAbbrs = {
      # General git shortcuts
      g = "git";

      # Git operations (from matchai's alias.fish)
      gs = "git status -sb";
      ga = "git add";
      gc = "git commit";
      gcm = "git commit -m";
      gca = "git commit --amend";
      gcl = "git clone";
      gco = "git checkout";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline --graph --decorate";
      gd = "git diff";
      gds = "git diff --staged";
      gf = "git fetch";

      # Yadm dotfiles manager (from matchai's alias.fish)
      ys = "yadm status -sb";
      ya = "yadm add";
      yc = "yadm commit";
      ycm = "yadm commit -m";
      yp = "yadm push";
      yd = "yadm diff";
      yds = "yadm diff --staged";

      # Nix shortcuts
      nrs = "sudo nixos-rebuild switch --flake .";
      nrb = "sudo nixos-rebuild build --flake .";
      hms = "home-manager switch --flake .";
      nfu = "nix flake update";
      nfc = "nix flake check";

      # Docker shortcuts
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
    };

    # Fisher plugin manager and plugins (merged from matchai's fishfile)
    plugins = [
      # Fisher plugin manager
      {
        name = "fisher";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "fisher";
          rev = "4.4.4";
          sha256 = "sha256-e8gIaVbuUzTwKtuMPNXBT5STeddYqQegduWBtURLT3M=";
        };
      }

      # Nix-shell enhancement for Fish
      {
        name = "nix-env.fish";
        src = pkgs.fetchFromGitHub {
          owner = "lilyball";
          repo = "nix-env.fish";
          rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
          sha256 = "sha256-RG/0rfhgq6aEKNZ0XwIqOaZ6K5S4+/Y5EEMnIdtfPhk=";
        };
      }

      # Enhanced FZF integration (from matchai's config)
      {
        name = "fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "8920367cf85eee5218cc25a11e209d46e2591e7a";
          sha256 = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
        };
      }
    ];

    # Fish shell initialization
    interactiveShellInit = ''
      # Disable greeting
      set fish_greeting

      # Add uv tool binaries to PATH
      fish_add_path -g ~/.local/bin

      # Add bun global packages to PATH
      set -gx BUN_INSTALL "$HOME/.bun"
      fish_add_path -g $BUN_INSTALL/bin

      # Enable VI mode (optional - uncomment if you want vim keybindings)
      # fish_vi_key_bindings

      # Fix Alt+Backspace to behave like Bash/Zsh (delete word, not entire quoted string)
      # Bash treats only [a-zA-Z0-9_] as word characters, so "-" is a word boundary
      function __backward_kill_word_bash
        set -l cmd (commandline -b)
        set -l pos (commandline -C)
        test $pos -le 0; and return

        set -l before (string sub -l $pos -- $cmd)
        set -l after (string sub -s (math $pos + 1) -- $cmd)
        set -l before_len (string length -- "$before")

        # Skip trailing whitespace, then delete word chars (alnum + underscore)
        set -l trimmed (string replace -r '[[:space:]]*[a-zA-Z0-9_]+$' "" -- $before)
        set -l trimmed_len (string length -- "$trimmed")

        # If nothing deleted, try deleting punctuation/special chars (dash, slash, etc.)
        if test "$trimmed_len" -eq "$before_len"
          set trimmed (string replace -r '[[:punct:]]+$' "" -- $before)
          set trimmed_len (string length -- "$trimmed")
        end

        # If still nothing, just delete whitespace
        if test "$trimmed_len" -eq "$before_len"
          set trimmed (string replace -r '[[:space:]]+$' "" -- $before)
          set trimmed_len (string length -- "$trimmed")
        end

        commandline -r -- "$trimmed$after"
        commandline -C $trimmed_len
      end
      bind \e\x7f __backward_kill_word_bash
      bind \cH __backward_kill_word_bash  # Ctrl+Backspace

      # Starship prompt initialization
      ${pkgs.starship}/bin/starship init fish | source

      # FZF configuration
      set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"

      # Jump shell integration (from matchai's config)
      status is-interactive; and ${pkgs.jump}/bin/jump shell fish | source

      # Syntax highlighting customization (from matchai's config)
      set fish_color_command 5cdb61
      set fish_color_param brgreen
      set fish_color_redirection bryellow
      set fish_color_comment brgrey
      set fish_color_error brred
      set fish_color_operator bryellow
      set fish_color_quote brgreen
      set fish_color_autosuggestion brgrey
      set fish_color_valid_path --underline
      set fish_color_cwd brblue
      set fish_color_cwd_root brred
      set fish_color_status brred
      set fish_color_search_match --background=brblue
      direnv hook fish | source
    '';

    # Login shell initialization
    loginShellInit = ''
      # Add any login-specific initialization here
    '';

    # Functions directory (Fish will auto-load functions from here)
    functions = {
      # Custom function for listing nix generations
      nix-generations = ''
        sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
      '';

      # Custom function for cleaning old generations
      nix-clean = ''
        sudo nix-collect-garbage --delete-older-than 7d
        home-manager expire-generations "-7 days"
      '';

      # Git commit with conventional commit format
      gcm = ''
        set -l type $argv[1]
        set -l msg $argv[2..-1]
        git commit -m "$type: $msg"
      '';
    };
  };
}
