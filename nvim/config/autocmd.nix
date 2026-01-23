{
  autoCmd = [
    {
      event = [ "BufEnter" "BufWinEnter" ];
      pattern = [ "*.go" ];
      desc = "Set tabstop to 4";
      callback = {
        __raw = ''
          function()
            local set = vim.opt -- set options
            set.tabstop = 4
            set.shiftwidth = 4
          end
        '';
      };
    }

    # Big file mode - disable expensive features for large files or long lines
    {
      event = [ "BufReadPre" "BufNewFile" ];
      pattern = [ "*" ];
      desc = "Big file mode - disable expensive features";
      callback = {
        __raw = ''
          function(args)
            local bufnr = args.buf
            local filename = args.file
            local max_filesize = 100 * 1024 -- 100KB
            local max_line_length = 1000

            -- Check file size
            local ok, stats = pcall(vim.loop.fs_stat, filename)
            local is_big_file = ok and stats and stats.size > max_filesize

            -- Defer line length check until buffer is loaded
            vim.api.nvim_create_autocmd("BufReadPost", {
              buffer = bufnr,
              once = true,
              callback = function()
                -- Check for long lines
                local has_long_lines = false
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 100, false) -- check first 100 lines
                for _, line in ipairs(lines) do
                  if #line > max_line_length then
                    has_long_lines = true
                    break
                  end
                end

                if is_big_file or has_long_lines then
                  vim.notify("Big file mode enabled", vim.log.levels.WARN)

                  -- Disable treesitter
                  vim.cmd("TSBufDisable highlight")
                  vim.cmd("TSBufDisable indent")

                  -- Disable indent-blankline
                  pcall(function() vim.cmd("IBLDisable") end)

                  -- Disable colorizer
                  pcall(function() vim.cmd("ColorizerDetachFromBuffer") end)

                  -- Disable smear cursor
                  pcall(function() vim.g.smear_cursor_enabled = false end)

                  -- Limit syntax highlighting column
                  vim.opt_local.synmaxcol = 200

                  -- Disable folding
                  vim.opt_local.foldenable = false

                  -- Disable swap and undo for performance
                  vim.opt_local.swapfile = false
                  vim.opt_local.undofile = false

                  -- Disable line numbers for rendering perf
                  vim.opt_local.number = false
                  vim.opt_local.relativenumber = false

                  -- Disable cursorline
                  vim.opt_local.cursorline = false
                end
              end,
            })
          end
        '';
      };
    }
  ];
}
