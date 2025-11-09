{
  plugins.neo-tree = {
    enable = true;

    settings = {
      auto_clean_after_session_restore = true;
      close_if_last_window = true;
      enable_diagnostics = true;
      enable_git_status = true;
      enable_modified_markers = true;
      enable_refresh_on_write = true;

      # Prevent Neo-tree from being replaced by other windows
      open_files_do_not_replace_types = [ "terminal" "trouble" "qf" ];

      default_component_configs = {
        indent = {
          with_expanders = true;
          expander_collapsed = "";
          expander_expanded = "";
          expander_highlight = "NeoTreeExpander";
        };
      };

      buffers = {
        follow_current_file = {
          enabled = true;
          leave_dirs_open = false;
        };
      };

      filesystem = {
        follow_current_file = {
          enabled = true;
          leave_dirs_open = false;
        };
        hijack_netrw_behavior = "disabled";
        use_libuv_file_watcher = true;
        filtered_items = {
          hide_dotfiles = false;
        };
      };

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
        position = "left";
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
