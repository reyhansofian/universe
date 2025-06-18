{ pkgs, lib, config, inputs, ... }:
let
  wallpapers = {
    waterfall = pkgs.nixos-artwork.wallpapers.waterfall.gnomeFilePath;
    catMacchiato =
      pkgs.nixos-artwork.wallpapers.catppuccin-macchiato.gnomeFilePath;
    darkGrey = pkgs.nixos-artwork.wallpapers.simple-dark-gray.gnomeFilePath;
    nineSolar =
      pkgs.nixos-artwork.wallpapers.nineish-solarized-light.gnomeFilePath;
  };
  listWallpapers = lib.attrValues wallpapers;

  toHyprpaperBind = lib.lists.flatten (lib.lists.imap1 (i: v: [
    "SUPER,${toString i},workspace,${toString i}"
    "SUPER,${toString i},exec,$w${toString i}"
  ]) listWallpapers);
in {
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.package = pkgs.hyprland;
  wayland.windowManager.hyprland.portalPackage =
    pkgs.xdg-desktop-portal-hyprland;
  wayland.windowManager.hyprland.xwayland.enable = true;
  wayland.windowManager.hyprland.systemd.enable = true;
  wayland.windowManager.hyprland.plugins = with pkgs.hyprlandPlugins;
    [
      # hy3
      # hyprgrass
      hyprbars
      # hyprtrails
    ];

  home.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    NIXOS_OZONE_WL = "1";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_PICTURES_DIR = "/home/reyhan/Pictures/";
    EDITOR = "nvim";
    BROWSER = "google-chrome-stable";
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = listWallpapers;
      wallpaper = lib.lists.map (v: "eDP-1,${v}") listWallpapers;
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
      ${builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css"}

      #pulseaudio-slider slider {
          min-height: 0px;
          min-width: 0px;
          opacity: 0;
          background-image: none;
          border: none;
          box-shadow: none;
      }

      #pulseaudio-slider trough {
          min-height: 10px;
          min-width: 100px;
          border-radius: 5px;
          background-color: black;
      }

      #pulseaudio-slider highlight {
          min-width: 10px;
          border-radius: 5px;
          background-color: green;
      }
    '';
    settings = [{
      output = [ "eDP-1" ];
      height = 30;
      layer = "top";
      position = "top";
      tray = { spacing = 15; };
      modules-center = [ "hyprland/workspaces" ];
      modules-left = [ "custom/launcher" "cpu" "memory" "battery" ];
      modules-right = [
        "pulseaudio"
        "pulseaudio/slider"
        "network"
        "temperature"
        "clock"
        "tray"
      ];
      battery = {
        format = "{capacity}% {icon}";
        format-alt = "{time} {icon}";
        format-charging = "{capacity}% ";
        format-icons = [ "" "" "" "" "" ];
        format-plugged = "{capacity}% ";
        states = {
          critical = 15;
          warning = 30;
          good = 95;
        };
      };
      "hyprland/workspaces" = {
        format = "{icon}";
        on-click = "activate";
        active-only = false;
        all-outputs = true;
        "format-icons" = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          "urgent" = "";
          "active" = "";
          "default" = "";
        };
        sort-by-number = true;
      };
      clock = {
        format-alt = "{:%Y-%m-%d}";
        tooltip-format = "{:%Y-%m-%d | %H:%M}";
      };
      cpu = {
        format = "{usage}% ";
        tooltip = false;
      };
      memory = { format = "{}% "; };
      network = {
        interval = 1;
        format-alt = "{ifname}: {ipaddr}/{cidr}";
        format-disconnected = "Disconnected ⚠";
        format-ethernet =
          "{ifname}: {ipaddr}/{cidr}   up: {bandwidthUpBits} down: {bandwidthDownBits}";
        format-linked = "{ifname} (No IP) ";
        format-wifi = "{essid} ({signalStrength}%) ";
      };
      pulseaudio = {
        format = "{volume}% {icon} {format_source}";
        format-bluetooth = "{volume}% {icon} {format_source}";
        format-bluetooth-muted = " {icon} {format_source}";
        format-icons = {
          car = "";
          default = [ "" "" "" ];
          handsfree = "";
          headphones = "";
          headset = "";
          phone = "";
          portable = "";
        };
        format-muted = " {format_source}";
        format-source = "{volume}% ";
        format-source-muted = "";
        on-click = "pavucontrol";
      };
      "pulseaudio/slider" = {
        "min" = 0;
        "max" = 100;
        "orientation" = "horizontal";
      };
      temperature = {
        critical-threshold = 80;
        format = "{temperatureC}°C {icon}";
        format-icons = [ "" ];
      };
    }];
  };

  wayland.windowManager.hyprland.systemd.variables = [ "--all" ];
  # Configuration is now in settings
  wayland.windowManager.hyprland.settings = (lib.pipe listWallpapers [
    (lib.lists.imap1 (i: v: {
      "$w${toString i}" = ''
        hyprctl hyprpaper wallpaper "eDP-1,${v}"
      '';
    }))
    (lib.attrsets.zipAttrsWith (_: v: v))
  ]) // {
    "exec-once" = [
      "$w1"
      "${lib.getExe pkgs.waybar}"
      "nm-applet"
      "blueman-applet"
      "$terminal"
      "${lib.getExe pkgs.fnott}"
    ];

    monitor = [ "eDPI-1,2880x1800@90,auto,1" ];

    "$terminal" = "ghostty";
    "$fileManager" = "nautilus";
    "$menu" = "wofi --show drun";

    env = [ "XCURSOR_SIZE,24" "HYPRCURSOR_SIZE,24" ];

    general = {
      gaps_in = 1;
      gaps_out = 10;
      border_size = 2;
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "col.inactive_border" = "rgba(595959aa)";
      resize_on_border = false;
      allow_tearing = false;
      layout = "dwindle";
    };

    decoration = {
      rounding = 10;
      rounding_power = 2;
      active_opacity = 1.0;
      inactive_opacity = 1.0;

      blur = {
        enabled = true;
        size = 8;
        passes = 3;
        vibrancy = 0.1696;
        new_optimizations = true;
        noise = 1.0e-2;
        contrast = 0.9;
        brightness = 0.8;
        popups = true;
      };

      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };
    };

    animations = {
      enabled = true;

      bezier = [
        "easeOutQuint,0.23,1,0.32,1"
        "easeInOutCubic,0.65,0.05,0.36,1"
        "linear,0,0,1,1"
        "almostLinear,0.5,0.5,0.75,1.0"
        "quick,0.15,0,0.1,1"
      ];

      animation = [
        "global, 1, 10, default"
        "border, 1, 5.39, easeOutQuint"
        "windows, 1, 4.79, easeOutQuint"
        "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
        "windowsOut, 1, 1.49, linear, popin 87%"
        "fadeIn, 1, 1.73, almostLinear"
        "fadeOut, 1, 1.46, almostLinear"
        "fade, 1, 3.03, quick"
        "layers, 1, 3.81, easeOutQuint"
        "layersIn, 1, 4, easeOutQuint, fade"
        "layersOut, 1, 1.5, linear, fade"
        "fadeLayersIn, 1, 1.79, almostLinear"
        "fadeLayersOut, 1, 1.39, almostLinear"
        "workspaces, 1, 1.94, almostLinear, fade"
        "workspacesIn, 1, 1.21, almostLinear, fade"
        "workspacesOut, 1, 1.94, almostLinear, fade"
      ];
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    master = { new_status = "master"; };

    misc = {
      force_default_wallpaper = -1;
      disable_hyprland_logo = true;
    };

    input = {
      kb_layout = "us";
      kb_variant = "";
      kb_model = "";
      kb_options = "caps:swapescape";
      kb_rules = "";
      follow_mouse = 1;
      sensitivity = 0;

      touchpad = { natural_scroll = true; };
    };

    gestures = {
      workspace_swipe = true;
      workspace_swipe_touch = true;
      workspace_swipe_use_r = true;
    };

    device = [{
      name = "epic-mouse-v1";
      sensitivity = 0;
    }];

    bind = [
      "$mainMod, Q, exec, $terminal"
      "$mainMod, C, killactive,"
      "$mainMod, M, exit,"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, V, togglefloating,"
      "$mainMod, R, exec, $menu"
      "$mainMod, P, pseudo,"
      "$mainMod, J, togglesplit,"
      "$mainMod, F, fullscreen, toggle,"
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"
      "$mainMod, S, togglespecialworkspace, magic"
      "$mainMod SHIFT, S, movetoworkspace, special:magic"
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
      # Screenshot a window
      "$mainMod, PRINT, exec, hyprshot -m window"
      # Screenshot a monitor
      ", PRINT, exec, hyprshot -m output"
      # Screenshot a region
      "$mainMod SHIFT, PRINT, exec, hyprshot -m region --clipboard-only"
    ] ++ toHyprpaperBind;

    bindel = [
      ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
      ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
    ];

    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];

    bindm =
      [ "$mainMod, mouse:272, movewindow" "$mainMod, mouse:273, resizewindow" ];

    windowrulev2 = [
      "float, class:^(org.gnome.Calculator)$"
      "float, class:^(org.gnome.Nautilus)$"
      "float, class:^(pavucontrol)$"
      "float, class:^(nm-connection-editor)$"
      "float, class:^(org.gnome.Settings)$"
      "float, class:^(xdg-desktop-portal)$"
      "float, class:^(xdg-desktop-portal-gnome)$"
      "float, fullscreen:1, class:^(Google-Chrome)$"
      "float, fullscreen:1, class:^(firefox)$"
      "suppressevent maximize, class:.*"
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
    ];

    "$mainMod" = "SUPER";

    "plugin" = {
      "hyprbars" = {
        "bar_height" = 28;
        "bar_color" = "rgb(1e1e1e)";
        "bar_text_size" = 11;
        "bar_button_padding" = 11;
        "bar_padding" = 10;
        "bar_precedence_over_border" = true;
        # hyperbars-button = [
        #   "rgb(ff4040), 10, 󰖭, 20, hyprctl dispatch killactive"
        #   "rgb(eeee11), 10, ,, hyprctl dispatch fullscreen 1"
        #   "rgb(a9a9a9), 10, , hyprctl dispatch togglefloating"
        #   "rgb(a9a9a9), 10, ,, hyprctl dispatch movetoworkspacesilent special:MinimizedApps"
        # ];
      };
    };
  };
}
