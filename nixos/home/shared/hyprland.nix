{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    pwvucontrol
    wofi
    polkit_gnome
    rose-pine-hyprcursor
    swaynotificationcenter
    gruvbox-dark-gtk
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Gruvbox-Dark-BL";
      package = pkgs.gruvbox-dark-gtk;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  home = {
    file = lib.mkMerge [
      {
        ".config/swaync" = {
          source = ./swaync/catppuccin-mocha;
          recursive = true;
        };
      }
      {
        ".config/waybar" = {
          source = ./waybar/nacho;
          recursive = true;
        };
      }
      {
        ".config/kitty/kitty.conf" = {
          source = ./kitty/kitty.conf;
        };
      }
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    systemd.variables = ["--all"];

    settings = {
      "$terminal" = "kitty";
      "$fileManager" = "nautilus";
      "$menu" = "walker";
      "$mainMod" = "SUPER";
      "$code" = "codium";
      "$browser" = "firefox";
      "$editor" = "gnome-text-editor";

      env = [
        "HYPRCURSOR_THEME, rose-pine-hyprcursor"
        "HYPRCURSOR_SIZE,24"
        "WLR_NO_HARDWARE_CURSORS,1"
        "NIXOS_OZONE_WL, 1"
        "GTK_THEME, Gruvbox-Dark-BL"
        "XDG_SESSION_DESKTOP, Hyprland"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "XDG_DESKTOP_DIR, $HOME/Desktop"
        "XDG_DOWNLOAD_DIR, $HOME/Downloads"
        "XDG_TEMPLATES_DIR, $HOME/Templates"
        "XDG_PUBLICSHARE_DIR, $HOME/Public"
        "XDG_DOCUMENTS_DIR, $HOME/Documents"
        "XDG_MUSIC_DIR, $HOME/Music"
        "XDG_PICTURES_DIR, $HOME/Pictures"
        "XDG_VIDEOS_DIR, $HOME/Videos"
        "HYPRSHOT_DIR, $HOME/Pictures/Screenshots"
        "QT_QPA_PLATFORMTHEME,qt6ct"
      ];

      exec-once = [
        "gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\""
        "gsettings set org.gnome.desktop.interface gtk-theme \"Gruvbox-Dark-BL\""
        "gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme true"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

        "swaync"
        "waybar"
        "awww-daemon"
        "sh -c 'sleep 1 && awww img \"$(find $HOME/Pictures/wallpapers -type f | shuf -n 1)\" --transition-type fade --transition-duration 2 && while true; do sleep 1800; awww img \"$(find $HOME/Pictures/wallpapers -type f | shuf -n 1)\" --transition-type fade --transition-duration 2; done'"

        "wl-clip-persist"
        "power-profiles-daemon"
        "nm-applet --no-agent"
        "blueman-applet"

        "[workspace special:terminal] kitty"
        "[workspace special:comms] telegram-desktop"
      ];

      animation = [
        "specialWorkspace, 1, 3, default, slidefadevert -10%"
      ];

      monitor = [
        "eDP-1, 1920x1080@60, 0x0, 1"
      ];

      general = {
        "$mainMod" = "SUPER";
        layout = "dwindle";
        gaps_in = 1;
        gaps_out = 1;
        border_size = 1;
        resize_on_border = true;
      };

      decoration = {
        rounding = 5;

        active_opacity = 1.0;
        inactive_opacity = 0.99;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        exit_window_retains_fullscreen = true;
      };

      input = {
        kb_layout = "us";
        kb_variant = "intl";

        follow_mouse = 0;

        sensitivity = 0;

        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
        };

        numlock_by_default = true;
      };

      gestures = {
      };

      group = {
        groupbar = {
          font_size = 8;
          gradients = true;
          "col.active" = "rgba(001d3cff)";
          "col.inactive" = "rgba(191919ff)";
          gaps_in = 0;
          gaps_out = 0;
          keep_upper_gap = false;
        };
      };

      bind = [
        "$mainMod, RETURN, exec, $terminal"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, Z, exec, $menu"
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, F, fullscreen, 1"
        "$mainMod, W, togglegroup"

        ", PRINT, exec, hyprshot -m output"
        "$mainMod, PRINT, exec, hyprshot -m window"
        "$mainMod SHIFT, PRINT, exec, hyprshot -m region"

        "ALT, Tab, changegroupactive, f"
        "ALT SHIFT, Tab, changegroupactive, b"

        "$mainMod, X, togglespecialworkspace, terminal"
        "$mainMod, C, togglespecialworkspace, comms"

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

        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        "$mainMod SHIFT, left, movewindoworgroup, l"
        "$mainMod SHIFT, right, movewindoworgroup, r"
        "$mainMod SHIFT, up, movewindoworgroup, u"
        "$mainMod SHIFT, down, movewindoworgroup, d"

        "$mainMod SHIFT, F, togglefloating"
        "$mainMod SHIFT, P, pseudo, "
        "$mainMod, P, pin"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];
      binde = [
        "$mainMod CTRL, left, resizeactive, -20 0"
        "$mainMod CTRL, right, resizeactive, 20 0"
        "$mainMod CTRL, up, resizeactive, 0 -20"
        "$mainMod CTRL, down, resizeactive, 0 20"
        "$mainMod CTRL SHIFT, left, moveactive, -20 0"
        "$mainMod CTRL SHIFT, right, moveactive, 20 0"
        "$mainMod CTRL SHIFT, up, moveactive, 0 -20"
        "$mainMod CTRL SHIFT, down, moveactive, 0 20"
      ];

      workspace = [
      ];
    };

    extraConfig = ''
      windowrule {
        name = suppress-maximize
        match:class = .*
        suppress_event = maximize
      }

      windowrule {
        name = fix-xwayland-drag
        match:class = ^$
        match:title = ^$
        match:xwayland = true
        match:float = true
        match:fullscreen = false
        match:pin = false
        no_focus = true
      }

      windowrule {
        name = pinned-border
        match:pin = true
        border_color = rgb(ff5500)
      }
    '';
  };
}
