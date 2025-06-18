{ lib, helpers, icons, ... }:

rec {
  # plugins.copilot-lua.enable = true;
  # plugins.copilot-lua.settings.suggestion.enabled = false;
  # plugins.copilot-lua.settings.panel.enabled = false;
  # plugins.windsurf-nvim.enable = true;
  # plugins.codeium-nvim.settings.config_path.__raw = # lua
  #   ''
  #     vim.env.HOME .. '/.config/sops-nix/secrets/codeium'
  #   '';

  plugins.claude-code.enable = true;
  plugins.neotest.enable = true;
  plugins.neotest.adapters.plenary.enable = true;

  autoCmd = [{
    # Disable cmp in neorepl
    event = [ "FileType" ];
    pattern = "neorepl";
    callback.__raw = helpers.mkLuaFun # lua
      ''
        require("cmp").setup.buffer { enabled = false }
      '';
  }];

  # plugins.cmp.settings.sources =
  #   lib.optionals plugins.windsurf-nvim.enable [{ name = "windsurf"; }]
  #   ++ lib.optionals plugins.copilot-lua.enable [{ name = "copilot"; }];

  plugins.which-key.settings.spec = [

    {
      __unkeyed-1 = "<leader>aa";
      __unkeyed-2 = "<cmd>AvanteAsk<cr>";
      icon = icons.robotFace;
      desc = "Open AI Ask";
    }

    {
      __unkeyed-1 = "<leader>ac";
      __unkeyed-2 = "<cmd>AvanteChat<cr>";
      icon = icons.robotFace;
      desc = "Open AI Chat";
    }

    {
      __unkeyed-1 = "<leader>ae";
      __unkeyed-2 = "<cmd>AvanteEdit<cr>";
      icon = icons.robotFace;
      desc = "Edit with instruction";
    }
  ];
}
