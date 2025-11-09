{
  plugins.neo-tree = {
    enable = true;

    buffers.followCurrentFile.enabled = true;
    autoCleanAfterSessionRestore = true;
    closeIfLastWindow = true;

    filesystem = {
      followCurrentFile.enabled = true;
      hijackNetrwBehavior = "open_current";
      useLibuvFileWatcher = true;
    };
    filesystem.filteredItems.hideDotfiles = false;

    enableDiagnostics = true;
    enableGitStatus = true;
    enableModifiedMarkers = true;
    enableRefreshOnWrite = true;

    settings = {
      source_selector = {
        winbar = true;
        content_layout = "start";
        sources = [
          {
            source = "filesystem";
            display_name = " File";
          }
          {
            source = "buffers";
            display_name = "󰈙 Bufs";
          }
          {
            source = "git_status";
            display_name = "󰊢 Git";
          }
          {
            source = "diagnostics";
            display_name = "󰒡 Diagnostic";
          }
        ];
      };

      window = {
        width = 30;
        mappings = {
          "<space>" = { };
          "[b" = { command = "prev_source"; };
          "]b" = { command = "next_source"; };
          # "F" = {
          #   command = ''
          #     require("telescope.nvim") and find_in_dir or nil
          #   '';
          # };
          # "O" = "system_open";
          # "Y" = "copy_selector";
          # "h" = "parent_or_close";
          # "l" = "child_or_open";
          # "o" = "open";
        };
      };

      event_handlers = [
        {
          event = "neo_tree_buffer_enter";
          handler.__raw = ''
            function(_) vim.opt_local.signcolumn = "auto" end
          '';
        }
      ];
    };
  };
}
