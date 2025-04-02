{
  autoCmd = [{
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
  }];
}
