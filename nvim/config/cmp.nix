{ ... }:

{
  plugins.cmp.enable = true;
  plugins.cmp.autoEnableSources = true;
  plugins.cmp.settings.sources = [
    { name = "nvim_lsp"; }
    { name = "nvim_lsp_signature_help"; }
    { name = "nvim_lsp_document_symbol"; }
    { name = "luasnip"; }
    { name = "calc"; }
    { name = "yanky"; }
    {
      name = "npm";
      keyword_length = 4;
    }
    {
      name = "emoji";
      trigger_characters = [ ":" ];
    }
    { name = "async_path"; }
  ];

  plugins.cmp.settings.experimental.ghost_text = true;
  plugins.cmp.settings.performance.debounce = 60;
  plugins.cmp.settings.performance.fetching_timeout = 200;
  plugins.cmp.settings.performance.max_view_entries = 30;
  plugins.cmp.settings.window.completion.winhighlight =
    "Normal:Pmenu,FloatBorder:Pmenu,Search:None";
  plugins.cmp.settings.window.completion.border = "rounded";
  plugins.cmp.settings.window.documentation.border = "rounded";
  plugins.cmp.settings.window.completion.col_offset = -3;
  plugins.cmp.settings.window.completion.side_padding = 0;
  plugins.cmp.settings.formatting.expandable_indicator = true;
  plugins.cmp.settings.formatting.fields = [ "kind" "abbr" "menu" ];
  plugins.cmp.settings.snippet.expand = # lua
    ''
      function(args) require('luasnip').lsp_expand(args.body) end
    '';

  plugins.cmp.settings.mapping."<C-e>" = "cmp.mapping.complete()";
  plugins.cmp.settings.mapping."<C-x>" = "cmp.mapping.close()";
  plugins.cmp.settings.mapping."<C-f>" = "cmp.mapping.scroll_docs(4)";
  plugins.cmp.settings.mapping."<S-f>" = "cmp.mapping.scroll_docs(-4)";
  plugins.cmp.settings.mapping."<CR>" =
    "cmp.mapping.confirm({ select = true })";
  plugins.cmp.settings.mapping."<S-Tab>" =
    "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
  plugins.cmp.settings.mapping."<Tab>" =
    "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";

  plugins.cmp.cmdline."/".mapping.__raw = "cmp.mapping.preset.cmdline()";
  plugins.cmp.cmdline."/".sources = [{ name = "buffer"; }];
  plugins.cmp.cmdline."?".mapping.__raw = "cmp.mapping.preset.cmdline()";
  plugins.cmp.cmdline."?".sources = [{ name = "buffer"; }];
  plugins.cmp.cmdline.":".mapping.__raw = "cmp.mapping.preset.cmdline()";
  plugins.cmp.cmdline.":".sources = [
    { name = "buffer"; }
    { name = "async_path"; }
    {
      name = "cmdline";
      option = { ignore_cmds = [ "Man" "!" ]; };
    }
  ];

  plugins.cmp-nvim-lsp.enable = true;
  plugins.cmp-nvim-lsp-signature-help.enable = true;
  plugins.cmp-nvim-lsp-document-symbol.enable = true;
  plugins.cmp-treesitter.enable = true;
  plugins.cmp-path.enable = true;
  plugins.cmp-buffer.enable = true;
  plugins.cmp-cmdline.enable = true;
  plugins.cmp-spell.enable = true;
  plugins.cmp-dictionary.enable = true;

  plugins.luasnip = {
    enable = true;
    settings = {
      enable_autosnippets = true;
      store_selection_keys = "<Tab>";
    };
  };

  plugins.cmp_luasnip.enable = true;

}
