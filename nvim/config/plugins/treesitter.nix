{
    plugins.treesitter = {
      enable = true;
      settings.indent.enable = true;
    };

    plugins.ts-context-commentstring = {
      enable = true;
    };

    plugins.ts-autotag = {
      enable = true;
    };

    plugins.treesitter-textobjects = {
      enable = true;

      settings = {
        select = {
          enable = true;
          lookahead = true;

          keymaps = {
            "ak" = { query_group = "@block.outer"; desc = "around block"; };
            "ik" = { query_group = "@block.inner"; desc = "inside block"; };
            "ac" = { query_group = "@class.outer"; desc = "around class"; };
            "ic" = { query_group = "@class.inner"; desc = "inside class"; };
            "a?" = { query_group = "@conditional.outer"; desc = "around conditional"; };
            "i?" = { query_group = "@conditional.inner"; desc = "inside conditional"; };
            "af" = { query_group = "@function.outer"; desc = "around function "; };
            "if" = { query_group = "@function.inner"; desc = "inside function "; };
            "al" = { query_group = "@loop.outer"; desc = "around loop"; };
            "il" = { query_group = "@loop.inner"; desc = "inside loop"; };
            "aa" = { query_group = "@parameter.outer"; desc = "around argument"; };
            "ia" = { query_group = "@parameter.inner"; desc = "inside argument"; };
          };
        };

        move = {
          enable = true;

          goto_next_start = {
            "]k" = { query_group = "@block.outer"; desc = "Next block start"; };
            "]f" = { query_group = "@function.outer"; desc = "Next function start"; };
            "]a" = { query_group = "@parameter.inner"; desc = "Next argument start"; };
          };

          goto_next_end = {
            "]K" = { query_group = "@block.outer"; desc = "Next block end"; };
            "]F" = { query_group = "@function.outer"; desc = "Next function end"; };
            "]A" = { query_group = "@parameter.inner"; desc = "Next argument end"; };
          };

          goto_previous_start = {
            "[k" = { query_group = "@block.outer"; desc = "Previous block start"; };
            "[f" = { query_group = "@function.outer"; desc = "Previous function start"; };
            "[a" = { query_group = "@parameter.inner"; desc = "Previous argument start"; };
          };

          goto_previous_end = {
            "[K" = { query_group = "@block.outer"; desc = "Previous block end"; };
            "[F" = { query_group = "@function.outer"; desc = "Previous function end"; };
            "[A" = { query_group = "@parameter.inner"; desc = "Previous argument end"; };
          };
        };
      };
    };
}
