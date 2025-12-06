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

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        command_timeout = 1300;
        scan_timeout = 50;
        right_format = "$time";
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[✗](bold red)";
        };
        env_var = { disabled = true; };
        time = {
          disabled = false;
          style = "#939594";
          format = "[$time]($style)";
        };
        cmd_duration = {
          style = "#f9a600";
          format = "\\[[$symbol$duration]($style)\\]";
        };

        azure = { disabled = true; };
        gcloud = { disabled = true; };
        aws = { disabled = true; };
        kubernetes = {
          symbol = "⎈ ";
          format = "\\[[$symbol($profile)($region)]($style)\\]";
        };

        bun = {
          symbol = " ";
          format = "\\[[$symbol($version )]($style)\\]";
        };
        golang = {
          symbol = " ";
          format = "\\[[$symbol($version )]($style)\\]";
        };
        nodejs = {
          symbol = " ";
          format = "\\[[$symbol($version)]($style)\\]";
        };
        python = {
          symbol = " ";
          format = "\\[[$symbol($version)]($style)\\]";
        };
        nix_shell = { format = "\\[[$symbol$state]($style)\\]"; };

        directory = {
          # style = "#c05303";
          truncate_to_repo = false;
          fish_style_pwd_dir_length = 1;
          format = "\\[[$path$read_only]($style)\\]";
          read_only = " ";
        };
        direnv = {
          disabled = false;
          symbol = " ";
          format = "\\[[$symbol$loaded/$allowed]($style)\\]";
        };

        git_branch = {
          format = "\\[[$symbol$branch]($style)\\]";
          style = "bright black";
        };
        git_commit = { tag_symbol = " "; };
        git_status = {
          # style = "#d8712c";
          format =
            "\\[[$conflicted$staged$modified$renamed$deleted$untracked$stashed$ahead_behind]($style)\\]";
          conflicted = "[][  \${count} ]($style)";
          staged = "[󰈖 $count ](green)";
          modified = "[ \${count} ](orange)";
          renamed = "[ \${count} ](purple)";
          deleted = "[ \${count} ](bold red)";
          untracked = "[? \${count} ](gray)";
          stashed = "[ \${count} ]($style)";
          ahead = "[ \${count} ]($style)";
          behind = "[ \${count} ]($style)";
          diverged =
            "[ ][ נּ ][ \${ahead_count} ][ \${behind_count} ]($style)";
        };
        git_state = {
          format = "\\[[$state( $progress_current/$progress_total)]($style)\\]";
          style = "bright-black";
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv = { enable = true; };
      enableZshIntegration = true;
    };

    gpg = {
      enable = true;
      settings = { use-agent = true; };
    };
  };
}
