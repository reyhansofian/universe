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
          "<space>" = "none";
          "<cr>" = "open_with_window_picker";
          "l" = "open";
          "h" = "close_node";
          "o" = "open";
          "S" = "open_split";
          "s" = "open_vsplit";
          "[b" = "prev_source";
          "]b" = "next_source";
        };
      };

      event_handlers = [
        {
          event = "neo_tree_buffer_enter";
          handler.__raw = ''
            function(_) vim.opt_local.signcolumn = "auto" end
          '';
        }
        {
          event = "file_opened";
          handler.__raw = ''
            function(_)
              require("neo-tree.command").execute({ action = "close" })
            end
          '';
        }
      ];
    };
  };
}
