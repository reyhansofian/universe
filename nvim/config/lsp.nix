{ pkgs, helpers, system, icons, lib, ... }: {
  highlightOverride.LspInlayHint = {
    fg = "#8B949E"; # Light gray text
    bg = "#21262D"; # Subtle dark background
    italic = true; # Italic for additional distinction
  };

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
    # {
    #   __unkeyed-1 = "<leader>r";
    #   __unkeyed-2 = "<cmd>Repl<cr>";
    #   desc = "Open Repl";
    # }
    {
      __unkeyed-1 = "//";
      __unkeyed-2 = "<cmd>nohlsearch<cr>";
      desc = "Clear search highlight";
    }
    # {
    #   __unkeyed-1 = "<leader><space>";
    #   __unkeyed-2 = "<cmd>Lspsaga term_toggle<cr>";
    #   desc = "Open Terminal";
    #
    # }
    {
      __unkeyed-1 = "gx";
      __unkeyed-2 = "<cmd>Trouble diagnostics toggle<cr>";
      desc = "Show diagnostics";

    }
    {
      __unkeyed-1 = "gX";
      __unkeyed-2 = "<cmd>Trouble diagnostics toggle filter.buf=0<cr><cr>";
      desc = "Show diagnostics Buffer";

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

  # plugins.typescript-tools = {
  #   enable = true;
  #   settings = {
  #     code_lens = "all";
  #     complete_function_calls = true;
  #     expose_as_code_action = "all";
  #     handlers = {
  #       "textDocument/publishDiagnostics" =
  #         # lua
  #         ''
  #           require("typescript-tools.api").filter_diagnostics(
  #             -- Ignore 'This may be converted to an async function' diagnostics.
  #             { 80006 }
  #           )
  #         '';
  #     };
  #
  #     # TypeScript server settings
  #     tsserver_file_preferences = {
  #       # Inlay hints
  #       includeInlayParameterNameHints = "all";
  #       includeInlayParameterNameHintsWhenArgumentMatchesName = true;
  #       includeInlayFunctionParameterTypeHints = true;
  #       includeInlayVariableTypeHints = true;
  #       includeInlayVariableTypeHintsWhenTypeMatchesName = true;
  #       includeInlayPropertyDeclarationTypeHints = true;
  #       includeInlayFunctionLikeReturnTypeHints = true;
  #       includeInlayEnumMemberValueHints = true;
  #
  #       # Import preferences
  #       includeCompletionsForModuleExports = true;
  #       quotePreference = "auto";
  #
  #       # Auto-imports
  #       includeCompletionsForImportStatements = true;
  #       includeCompletionsWithSnippetText = true;
  #       includeAutomaticOptionalChainCompletions = true;
  #     };
  #
  #     # Disable semantic tokens (can cause performance issues)
  #     disable_member_code_lens = false;
  #
  #     # Organize imports on save
  #     tsserver_format_options = {
  #       allowIncompleteCompletions = false;
  #       allowRenameOfImportPath = false;
  #     };
  #
  #     onAttach = {
  #       function = ''
  #         -- Enable CodeLens refresh
  #         if client.server_capabilities.codeLensProvider then
  #           vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "InsertLeave"}, {
  #             buffer = bufnr,
  #             callback = vim.lsp.codelens.refresh,
  #           })
  #
  #           -- Initial refresh
  #           vim.lsp.codelens.refresh()
  #         end
  #       '';
  #     };
  #   };
  # };

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

          local is_eslint_active = function()
            for _, client in ipairs(clients) do
              if client.name == "eslint" and client.attached_buffers[bufnr] then
                return true
              end
            end
            return false
          end

          for _, client in ipairs(clients) do
            if is_eslint_active() then
              if client.name == "typescript-tools" or client.name == "jsonls" then
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
              end
              if client.name == "biome" then
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
              end
            end
          end

          -- for _, client in ipairs(clients) do
          --   if is_biome_active() then
          --     if client.name == "typescript-tools" or client.name == "jsonls" then
          --       client.server_capabilities.documentFormattingProvider = false
          --       client.server_capabilities.documentRangeFormattingProvider = false
          --     end
          --     if client.name == "eslint" then
          --       client.stop()
          --     end
          --   end
          -- end
        end
      '';
  }];

  plugins.lsp = {
    enable = true;

    # Disable lazyLoad to avoid breaking change with types.luaInline removal
    lazyLoad.enable = false;

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
            hint_prefix = "H ",
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
      lspSymbol("Hint", "")
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
      ts_ls.autostart = true;
      ts_ls.extraOptions = {
        init_options = {
          preferences = {
            # Inlay hints (similar to typescript-tools)
            includeInlayParameterNameHints = "all";
            includeInlayParameterNameHintsWhenArgumentMatchesName = true;
            includeInlayFunctionParameterTypeHints = true;
            includeInlayVariableTypeHints = true;
            includeInlayVariableTypeHintsWhenTypeMatchesName = true;
            includeInlayPropertyDeclarationTypeHints = true;
            includeInlayFunctionLikeReturnTypeHints = true;
            includeInlayEnumMemberValueHints = true;

            # Import preferences
            includeCompletionsForModuleExports = true;
            quotePreference = "auto";

            # Auto-imports and completions
            includeCompletionsForImportStatements = true;
            includeCompletionsWithSnippetText = true;
            includeAutomaticOptionalChainCompletions = true;

            # Display preferences for longer hints
            displayPartsForJSDoc = true;
            generateReturnInDocTemplate = true;

            # Formatting
            allowIncompleteCompletions = false;
            allowRenameOfImportPath = false;
          };
        };
        on_attach.__raw = # lua
          ''
            function(client, bufnr)
              -- Enable inlay hints if supported
              if client.server_capabilities.inlayHintProvider then
                vim.lsp.inlay_hint.enable(true)
              end

              -- Enable CodeLens refresh (similar to typescript-tools)
              if client.server_capabilities.codeLensProvider then
                vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "InsertLeave"}, {
                  buffer = bufnr,
                  callback = vim.lsp.codelens.refresh,
                })

                -- Initial refresh
                vim.lsp.codelens.refresh()
              end

              -- Format on save with Biome or ESLint preference
              vim.api.nvim_create_autocmd("BufWritePre", {
                group = vim.api.nvim_create_augroup("TsLspFormatting", {}),
                buffer = bufnr,
                callback = function()
                  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
                  local biome_client = nil
                  local eslint_client = nil

                  for _, c in ipairs(clients) do
                    if c.name == "biome" then
                      biome_client = c
                    elseif c.name == "eslint" then
                      eslint_client = c
                    end
                  end

                  -- Prefer Biome, then ESLint, then ts_ls
                  if biome_client then
                    vim.lsp.buf.format({ name = "biome" })
                  elseif eslint_client then
                    vim.lsp.buf.format({ name = "eslint" })
                  else
                    vim.lsp.buf.format({ name = "ts_ls" })
                  end
                end,
              })
            end
          '';
        handlers = {
          # Filter out specific diagnostics (similar to typescript-tools)
          "textDocument/publishDiagnostics".__raw = # lua
            ''
              function(err, result, ctx, config)
                if result and result.diagnostics then
                  -- Filter out 'This may be converted to an async function' diagnostics
                  result.diagnostics = vim.tbl_filter(function(diagnostic)
                    return diagnostic.code ~= 80006
                  end, result.diagnostics)
                end
                vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
              end
            '';
        };
      };

      gopls.enable = true;
      gopls.autostart = true;
      gopls.settings = {
        filetypes = [ "go" ];
        gopls = {
          hints = {
            assignVariableTypes = true;
            compositeLiteralFields = true;
            compositeLiteralTypes = true;
            constantValues = true;
            functionTypeParameters = true;
            parameterNames = true;
            rangeVariableTypes = true;
          };

          analyses = {
            unusedparams = true;
            unreachable = true;
            unusedwrite = true;
            useany = true;
            nilness = true;
            shadow = true;
          };

          staticcheck = true;
          gofumpt = true;
          codelenses = { gc_details = true; };

          usePlaceholders = true;
          completionDocumentation = true;
          deepCompletion = true;
          matcher = "Fuzzy";

          # Semantic tokens
          semanticTokens = true;

          # Go vulncheck
          vulncheck = "Imports";
        };

        onAttach = {
          function = ''
            -- Enable CodeLens refresh
            if client.server_capabilities.codeLensProvider then
              vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "InsertLeave"}, {
                buffer = bufnr,
                callback = vim.lsp.codelens.refresh,
              })
              vim.lsp.codelens.refresh()
            end

            -- Auto-organize imports on save
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                local params = vim.lsp.util.make_range_params()
                params.context = {only = {"source.organizeImports"}}
                local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
                for _, res in pairs(result or {}) do
                  for _, r in pairs(res.result or {}) do
                    if r.edit then
                      vim.lsp.util.apply_workspace_edit(r.edit, "utf-16")
                    else
                      vim.lsp.buf.execute_command(r.command)
                    end
                  end
                end
              end
            })
          '';
        };
      };

      hls.enable = true;
      hls.autostart = true;
      hls.installGhc = false;

      # htmx.enable = !pkgs.stdenv.isDarwin;
      # htmx.autostart = true;

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

      ansiblels.enable = lib.mkForce false;
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
