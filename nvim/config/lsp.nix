{ pkgs, helpers, system, icons, ... }:

{
  highlightOverride.LspInlayHint.link = "InclineNormalNc";

  extraPackages = with pkgs; [
    nixfmt-classic
    manix
    typescript-language-server
  ];

  extraPlugins = with pkgs.vimPlugins; [
    codi-vim # repl
    telescope-manix
    neorepl-nvim
    luasnip
    lsp-inlayhints-nvim
  ];

  # make custom command
  userCommands.LspInlay.desc = "Toggle Inlay Hints";
  userCommands.LspInlay.command.__raw = helpers.mkLuaFun
    # lua
    ''
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    '';

  filetype.extension = { };

  plugins.telescope.enabledExtensions = [ "manix" ];
  plugins.telescope.keymaps.fN.options.desc = "Find with manix";
  plugins.telescope.keymaps.fN.action = "manix";

  plugins.which-key.settings.spec = [
    {
      __unkeyed-1 = "<leader>r";
      __unkeyed-2 = "<cmd>Repl<cr>";
      desc = "Open Repl";
    }
    {
      __unkeyed-1 = "//";
      __unkeyed-2 = "<cmd>nohlsearch<cr>";
      desc = "Clear search highlight";
    }
    {
      __unkeyed-1 = "<leader><space>";
      __unkeyed-2 = "<cmd>Lspsaga term_toggle<cr>";
      desc = "Open Terminal";

    }
    {
      __unkeyed-1 = "ge";
      __unkeyed-2 = "<cmd>Trouble<cr>";
      desc = "Show diagnostics";

    }
    {
      __unkeyed-1 = "[e";
      __unkeyed-2 = "<cmd>Lspsaga diagnostic_jump_next<cr>";
      desc = "Next Diagnostic";

    }
    {
      __unkeyed-1 = "]e";
      __unkeyed-2 = "<cmd>Lspsaga diagnostic_jump_prev<cr>";
      desc = "Previous Diagnostic";

    }
    {
      __unkeyed-1 = "K";
      __unkeyed-2 = "<cmd>Lspsaga hover_doc<cr>";
      desc = "Code Hover";

    }
    {
      __unkeyed-1 = "F";
      __unkeyed-2 = "<cmd>Format<cr>";
      desc = "Format the current buffer";

    }
    {
      __unkeyed-1 = "gl";
      __unkeyed-2 = "<cmd>LspInfo<cr>";
      desc = "Show LSP Info";

    }
    {
      __unkeyed-1 = "gt";
      __unkeyed-2 = "<cmd>Lspsaga outline<cr>";
      desc = "Code Outline";

    }
    {
      __unkeyed-1 = "ga";
      __unkeyed-2 = "<cmd>Lspsaga code_action<cr>";
      desc = "Code Action";

    }
    {
      __unkeyed-1 = "gi";
      __unkeyed-2 = "<cmd>Lspsaga incoming_calls<cr>";
      desc = "Incoming Calls";

    }
    {
      __unkeyed-1 = "go";
      __unkeyed-2 = "<cmd>Lspsaga outgoing_calls<cr>";
      desc = "Outgoing Calls";

    }
    {
      __unkeyed-1 = "gD";
      __unkeyed-2 = "<cmd>Lspsaga goto_definition<cr>";
      desc = "Go to Definition";

    }
    {
      __unkeyed-1 = "gd";
      __unkeyed-2 = "<cmd>Lspsaga peek_definition<cr>";
      desc = "Peek Definition";

    }
    {
      __unkeyed-1 = "gr";
      __unkeyed-2 = "<cmd>Lspsaga rename<cr>";
      desc = "Code Rename";
      icon = icons.gearSM;

    }
    {
      __unkeyed-1 = "gs";
      __unkeyed-2 = ''<cmd>lua require("wtf").search() <cr>'';
      desc = "Search diagnostic with Google";

    }
    {
      __unkeyed-1 = "gF";
      __unkeyed-2 = "<cmd>Lspsaga finder<cr>";
      desc = "Code Finder";

    }
    {
      __unkeyed-1 = "tI";
      __unkeyed-2 = "<cmd>LspInlay<cr>";
      desc = "Toggle Inlay Hints";

    }
    {
      __unkeyed-1 = "flr";
      __unkeyed-2 = "<cmd>lua require'telescope.builtin'.lsp_references()<cr>";
      desc = "[Lsp] Find References";
    }
    {
      __unkeyed-1 = "fic";
      __unkeyed-2 =
        "<cmd>lua require'telescope.builtin'.lsp_incoming_calls()<cr>";

    }
    {
      __unkeyed-1 = "foc";
      __unkeyed-2 =
        "<cmd>lua require'telescope.builtin'.lsp_outgoing_calls()<cr>";
      desc = "[Lsp] Find Outgoing Calls";
    }
    {
      __unkeyed-1 = "fds";
      __unkeyed-2 =
        "<cmd>lua require'telescope.builtin'.lsp_document_symbols()<cr>";
      desc = "[Lsp] Find Document Symbols";
    }
    {
      __unkeyed-1 = "fws";
      __unkeyed-2 =
        "<cmd>lua require'telescope.builtin'.lsp_workspace_symbols()<cr>";
      desc = "[Lsp] Find Workspace Symbols";
    }
    {
      __unkeyed-1 = "fdws";
      __unkeyed-2 =
        "<cmd>lua require'telescope.builtin'.lsp_dynamic_workspace_symbols()<cr>";
      desc = "[Lsp] Find Dynamic Workspace Symbols";
    }
    {
      __unkeyed-1 = "fld";
      __unkeyed-2 = "<cmd>lua require'telescope.builtin'.diagnostics()<cr>";
      desc = "[Lsp] Find Diagnostics";
    }
    {
      __unkeyed-1 = "fli";
      __unkeyed-2 =
        "<cmd>lua require'telescope.builtin'.lsp_implementations()<cr>";
      desc = "[Lsp] Find Implementations";
    }
    {
      __unkeyed-1 = "flD";
      __unkeyed-2 = "<cmd>lua require'telescope.builtin'.lsp_definitions()<cr>";
      desc = "[Lsp] Find Definitions";
    }
    {
      __unkeyed-1 = "flt";
      __unkeyed-2 =
        "<cmd>lua require'telescope.builtin'.lsp_type_definitions()<cr>";
      desc = "[Lsp] Find Type Definitions";
    }
  ];

  plugins.typescript-tools.enable = true;
  plugins.typescript-tools.settings.code_lens = "references_only";
  plugins.typescript-tools.settings.complete_function_calls = true;
  plugins.typescript-tools.settings.expose_as_code_action = "all";
  plugins.typescript-tools.settings.handlers = {
    "textDocument/publishDiagnostics" =
      # lua
      ''
        require("typescript-tools.api").filter_diagnostics(
          -- Ignore 'This may be converted to an async function' diagnostics.
          { 80006 }
        )
      '';
  };

  autoCmd = [{
    event = [ "LspAttach" ];
    callback.__raw = # lua
      ''
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          local clients = vim.lsp.buf_get_clients()
          local is_biome_active = function()
            for _, client in ipairs(clients) do
              if client.name == "biome" and client.attached_buffers[bufnr] then
                return true
              end
            end
            return false
          end

          for _, client in ipairs(clients) do
            if is_biome_active() then
              if client.name == "typescript-tools" or client.name == "jsonls" then
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
              end
              if client.name == "eslint" then
                client.stop()
              end
            end
          end
        end
      '';
  }];

  plugins.lsp = {
    enable = true;

    onAttach = ''
      function onAttach(client, bufnr)
        local signature_ok, signature = pcall(require, "lsp_signature")
        if signature_ok then
          local signature_config = {
            bind = true,
            doc_lines = 0,
            floating_window = true,
            fix_pos = true,
            hint_enable = true,
            hint_prefix = " ",
            hint_scheme = "String",
            hi_parameter = "Search",
            max_height = 22,
            max_width = 120,      -- max_width of signature floating_window, line will be wrapped if exceed max_width
            handler_opts = {
              border = "rounded", -- double, single, shadow, none
            },
            zindex = 200,         -- by default it will be on top of all floating windows, set to 50 send it to bottom
            padding = "",         -- character to pad on left and right of signature can be ' ', or '|'  etc
          }
          signature.on_attach(signature_config, bufnr)
        end

        require('lsp-inlayhints').on_attach(client, bufnr, false)
      end
    '';

    postConfig = ''
      local function lspSymbol(name, icon)
        local hl = "DiagnosticSign" .. name
        vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
      end

      lspSymbol("Error", "")
      lspSymbol("Info", "")
      lspSymbol("Hint", "")
      lspSymbol("Warn", "")
    '';

    servers = {
      ccls.enable = true;
      ccls.autostart = true;

      bashls.enable = true;
      bashls.autostart = true;

      dockerls.enable = true;
      dockerls.autostart = true;

      biome.enable = true;
      biome.autostart = true;

      eslint.enable = true;
      eslint.autostart = true;

      ts_ls.enable = true;
      ts_ls.autostart = false;
      ts_ls.rootDir = # lua
        ''
          require('lspconfig.util').root_pattern('.git')
        '';

      gopls.enable = true;
      gopls.autostart = true;
      gopls.rootDir =
        ''require("lspconfig.util").root_pattern("go.work", "go.mod", ".git")'';
      gopls.extraOptions.settings.gopls.hints = {
        assignVariableTypes = true;
        compositeLiteralFields = true;
        compositeLiteralTypes = true;
        constantValues = true;
        functionTypeParameters = true;
        parameterNames = true;
        rangeVariableTypes = true;
      };
      gopls.extraOptions.settings.gopls.analyses = { unusedparams = true; };
      gopls.extraOptions.settings.gopls.staticcheck = true;
      gopls.extraOptions.settings.gopls.gofumpt = true;
      gopls.extraOptions.settings.gopls.codelenses = {
        usePlaceholders = true;
      };

      hls.enable = true;
      hls.autostart = true;
      hls.installGhc = false;

      htmx.enable = !pkgs.stdenv.isDarwin;
      htmx.autostart = true;

      jsonls.enable = true;
      jsonls.autostart = true;
      jsonls.extraOptions.settings.json = {
        validate.enable = true;
        schemas = [
          {
            description = "nixd schema";
            fileMatch = [ ".nixd.json" "nixd.json" ];
            url =
              "https://raw.githubusercontent.com/nix-community/nixd/main/nixd/docs/nixd-schema.json";
          }
          {
            description = "Turbo.build configuration file";
            fileMatch = [ "turbo.json" ];
            url = "https://turbo.build/schema.json";
          }
          {
            description = "TypeScript compiler configuration file";
            fileMatch = [ "tsconfig.json" "tsconfig.*.json" ];
            url = "https://json.schemastore.org/tsconfig.json";
          }
        ];
      };

      lua_ls.enable = true;
      lua_ls.autostart = true;

      rust_analyzer.enable = true;
      rust_analyzer.autostart = true;
      rust_analyzer.installCargo = false;
      rust_analyzer.installRustc = false;

      ocamllsp.enable = true;
      ocamllsp.autostart = true;
      ocamllsp.package = pkgs.ocamlPackages.ocaml-lsp;
      ocamllsp.settings.codelens.enable = false;
      ocamllsp.settings.extendedHover.enable = true;
      ocamllsp.settings.duneDiagnostics.enable = false;
      ocamllsp.settings.inlayHints.enable = true;

      nixd.enable = true;
      nixd.autostart = true;
      nixd.settings = {
        nixpkgs.expr = "import <nixpkgs> { }";
        formatting.command = [ "nixfmt" ];
        options = let flake = ''(builtins.getFlake "${./../..}")'';
        in {
          # nix-darwin.expr = ''${flake}.darwinConfigurations.eR17x.options'';
          home-manager.expr =
            "${system}.home-manager.users.type.getSubOptions []";
          nixvim.expr = "${flake}.packages.${system}.nvim.options";
        };
      };

      yamlls.enable = true;
      yamlls.autostart = true;
    };
  };

  plugins.lsp-format.enable = true;
  plugins.lsp-format.settings.gopls.exclude = [ "gopls" ];
  plugins.lsp-format.settings.gopls.force = true;
  plugins.lsp-format.settings.gopls.order = [ "gopls" "efm" ];
  plugins.lsp-format.settings.gopls.sync = true;

  plugins.lspkind.enable = true;
  plugins.lspkind.symbolMap.Codeium = icons.code;
  plugins.lspkind.symbolMap.Copilot = icons.robotFace;
  plugins.lspkind.symbolMap.Suggestion = icons.wand;
  plugins.lspkind.symbolMap.TabNine = icons.face;
  plugins.lspkind.symbolMap.Supermaven = icons.star;
  plugins.lspkind.symbolMap.Error = icons.cross4;
  plugins.lspkind.symbolMap.Hint = icons.hint;
  plugins.lspkind.symbolMap.Info = icons.info2;
  plugins.lspkind.symbolMap.Warn = icons.warning2;
  plugins.lspkind.symbolMap.DiagnosticSignError = icons.cross4;
  plugins.lspkind.symbolMap.DiagnosticSignHint = icons.hint;
  plugins.lspkind.symbolMap.DiagnosticSignInfo = icons.info2;
  plugins.lspkind.symbolMap.DiagnosticSignWarn = icons.warning2;
  plugins.lspkind.cmp.enable = true;
  plugins.lspkind.cmp.maxWidth = 24;
  plugins.lspkind.cmp.after = # lua
    ''
      function(entry, vim_item, kind)
        local strings = vim.split(kind.kind, "%s", { trimempty = true })
        kind.kind = " " .. (strings[1] or "") .. " "
        kind.menu = "   ⌈" .. (strings[2] or "") .. "⌋"
        return kind
      end
    '';

  plugins.lspsaga.enable = true;
  plugins.lspsaga.lightbulb.sign = false;
  plugins.lspsaga.lightbulb.virtualText = true;
  plugins.lspsaga.lightbulb.debounce = 40;
  plugins.lspsaga.ui.codeAction = icons.gearSM;

  plugins.trouble.enable = true;
  plugins.wtf.enable = true;
  plugins.nvim-autopairs.enable = true;
}
