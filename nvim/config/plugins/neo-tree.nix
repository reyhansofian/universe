{
  plugins.neo-tree = {
    enable = true;

    settings = {
      default_component_configs = {
        indent = {
          with_expanders = true;
          expander_collapsed = "";
          expander_expanded = "";
        };
      };

      buffers = {
        follow_current_file = {
          enabled = true;
        };
      };

      auto_clean_after_session_restore = true;
      close_if_last_window = false;

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

      filesystem = {
        follow_current_file = {
          enabled = true;
        };
        hijack_netrw_behavior = "open_default";
        use_libuv_file_watcher = true;
        filtered_items = {
          hide_dotfiles = false;
        };
      };

      enable_diagnostics = true;
      enable_git_status = true;
      enable_modified_markers = true;
      enable_refresh_on_write = true;

      window = {
        position = "right";
        width = 30;
        mappings = {
          "<space>" = { };
          "[b" = { command = "prev_source"; };
          "]b" = { command = "next_source"; };
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
