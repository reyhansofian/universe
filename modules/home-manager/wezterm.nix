{ pkgs, ... }:
let
  # Script to paste clipboard images as file paths for Claude Code
  # Usage: Ctrl+Alt+V in WezTerm (requires Windows-side WezTerm config)
  #
  # Add to your Windows WezTerm config (~/.config/wezterm/wezterm.lua):
  #
  #   config.keys = {
  #     {
  #       key = 'v',
  #       mods = 'CTRL|ALT',
  #       action = wezterm.action_callback(function(window, pane)
  #         local handle = io.popen('wsl.exe clip2path')
  #         local result = handle:read('*a')
  #         handle:close()
  #         result = result:gsub('%s+$', '')
  #         pane:send_text(result)
  #       end),
  #     },
  #   }
  #
  clip2path = pkgs.writeShellScriptBin "clip2path" ''
    set -e

    # WSL2: Use PowerShell to check Windows clipboard for images
    if grep -qi microsoft /proc/version 2>/dev/null; then
      has_image=$(powershell.exe -NoProfile -Command '
        Add-Type -AssemblyName System.Windows.Forms
        $img = [System.Windows.Forms.Clipboard]::GetImage()
        if ($img) { "yes" } else { "no" }
      ' | tr -d '\r')

      if [ "$has_image" = "yes" ]; then
        file="/tmp/clip_$(date +%s).png"
        win_path=$(wslpath -w "$file")
        powershell.exe -NoProfile -Command "
          Add-Type -AssemblyName System.Windows.Forms
          \$img = [System.Windows.Forms.Clipboard]::GetImage()
          \$img.Save('$win_path', [System.Drawing.Imaging.ImageFormat]::Png)
        "
        echo -n "$file"
      else
        powershell.exe -NoProfile -Command 'Get-Clipboard' | tr -d '\r'
      fi
    elif [ -n "$WAYLAND_DISPLAY" ]; then
      types=$(wl-paste --list-types)
      if grep -q '^image/' <<<"$types"; then
        ext=$(grep -m1 '^image/' <<<"$types" | cut -d/ -f2 | cut -d';' -f1)
        file="/tmp/clip_$(date +%s).''${ext}"
        wl-paste > "$file"
        echo -n "$file"
      else
        wl-paste --no-newline
      fi
    elif [ -n "$DISPLAY" ]; then
      types=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null || echo "")
      if grep -q '^image/' <<<"$types"; then
        ext=$(grep -m1 '^image/' <<<"$types" | cut -d/ -f2 | cut -d';' -f1)
        file="/tmp/clip_$(date +%s).''${ext}"
        xclip -selection clipboard -t "image/''${ext}" -o > "$file"
        echo -n "$file"
      else
        xclip -selection clipboard -o
      fi
    fi
  '';
in
{
  home.packages = [ clip2path ];
}
