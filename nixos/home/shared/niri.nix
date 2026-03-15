{ pkgs, lib, ... }:

let
  waybar-niri-windows = pkgs.buildGoModule rec {
    pname = "waybar-niri-windows";
    version = "2.3.0";

    src = pkgs.fetchFromGitHub {
      owner = "calico32";
      repo = "waybar-niri-windows";
      rev = "v${version}";
      hash = "sha256-7OEyJ4K7JXCdMILxcY5g3ldmSMPAiea5OZcsyvDdL9k=";
    };

    vendorHash = "sha256-jK87vZYfUe8znk65SmJ1mN8qP5K3dtt950hKGWTYXs4=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.gtk3 ];

    buildPhase = ''
      runHook preBuild
      go build -buildmode=c-shared -o waybar-niri-windows.so ./main
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp waybar-niri-windows.so $out/lib/
      runHook postInstall
    '';
  };
in
{
  home.file.".config/waybar/waybar-niri-windows.so" = {
    source = "${waybar-niri-windows}/lib/waybar-niri-windows.so";
    force = true;
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  xdg.configFile."niri/config.kdl".text = ''
    input {
      keyboard {
        xkb {
          layout "us"
          variant "intl"
        }
        numlock
      }

      touchpad {
        tap
        dwt
      }

      mouse {
      }
    }

    output "eDP-1" {
      mode "1920x1080@60"
      position x=0 y=0
    }

    layout {
      gaps 0
      default-column-width { proportion 0.5; }

      focus-ring {
        off
      }

      border {
        width 2
        active-color "#89b4fa"
        inactive-color "transparent"
      }
    }

    spawn-at-startup "swaync"
    spawn-at-startup "waybar" "-c" "${builtins.toString ./waybar/niri/config}" "-s" "${builtins.toString ./waybar/niri/style.css}"
    spawn-at-startup "swww-daemon"
    spawn-at-startup "sh" "-c" "sleep 1 && swww img \"$(find $HOME/Pictures/wallpapers -type f | shuf -n 1)\" --transition-type fade --transition-duration 2 && while true; do sleep 1800; swww img \"$(find $HOME/Pictures/wallpapers -type f | shuf -n 1)\" --transition-type fade --transition-duration 2; done"
    spawn-at-startup "wl-clip-persist"
    spawn-at-startup "nm-applet" "--no-agent"
    spawn-at-startup "blueman-applet"
    spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "firefox"
    spawn-at-startup "kitty"
    spawn-at-startup "telegram-desktop"
    spawn-at-startup "slack" "--ozone-platform=wayland" "--enable-features=UseOzonePlatform,WaylandWindowDecorations"

    window-rule {
      shadow {
        off
      }
      draw-border-with-background false
    }

    window-rule {
      match app-id="firefox"
      open-on-workspace "browser"
    }

    window-rule {
      match at-startup=true app-id="kitty"
      open-on-workspace "terminal"
    }

    window-rule {
      match app-id="org.telegram.desktop"
      open-on-workspace "comms"
    }

    window-rule {
      match at-startup=true app-id="Slack"
      open-on-workspace "comms"
    }

    environment {
      GTK_THEME "Gruvbox-Dark-BL"
      NIXOS_OZONE_WL "1"
      DISPLAY ":0"
    }

    cursor {
      xcursor-theme "Adwaita"
      xcursor-size 24
    }

    workspace "terminal" {
      open-on-output "eDP-1"
    }
    workspace "browser" {
      open-on-output "eDP-1"
    }
    workspace "comms" {
      open-on-output "eDP-1"
    }

    prefer-no-csd

    screenshot-path "$HOME/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png"

    binds {
      // App launchers
      Mod+Return { spawn "kitty"; }
      Mod+E { spawn "nautilus"; }
      Mod+Z { spawn "walker"; }

      // Window switching
      Alt+Tab { focus-column-right-or-first; }
      Alt+Shift+Tab { focus-column-left-or-last; }

      // Overview
      Mod+Tab { toggle-overview; }

      // Window management
      Mod+Q { close-window; }
      Mod+M { quit; }
      Mod+F { fullscreen-window; }
      Mod+W { consume-or-expel-window-left; }
      Mod+S { consume-or-expel-window-right; }
      Mod+Shift+F { maximize-column; }

      // Screenshot
      Print { screenshot-screen; }
      Mod+Print { screenshot-window; }
      Mod+Shift+Print { screenshot; }

      // Focus
      Mod+Left { focus-column-left; }
      Mod+Right { focus-column-right; }
      Mod+Up { focus-window-or-workspace-up; }
      Mod+Down { focus-window-or-workspace-down; }

      // Move windows
      Mod+Shift+Left { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up { move-window-up-or-to-workspace-up; }
      Mod+Shift+Down { move-window-down-or-to-workspace-down; }

      // Resize
      Mod+Ctrl+Left { set-column-width "-5%"; }
      Mod+Ctrl+Right { set-column-width "+5%"; }
      Mod+Ctrl+Up { set-window-height "-5%"; }
      Mod+Ctrl+Down { set-window-height "+5%"; }

      // Workspaces (offset by 3 for named workspaces: terminal, browser, comms)
      Mod+1 { focus-workspace 4; }
      Mod+2 { focus-workspace 5; }
      Mod+3 { focus-workspace 6; }
      Mod+4 { focus-workspace 7; }
      Mod+5 { focus-workspace 8; }
      Mod+6 { focus-workspace 9; }
      Mod+7 { focus-workspace 10; }
      Mod+8 { focus-workspace 11; }
      Mod+9 { focus-workspace 12; }
      Mod+0 { focus-workspace 13; }

      Mod+Shift+1 { move-column-to-workspace 4; }
      Mod+Shift+2 { move-column-to-workspace 5; }
      Mod+Shift+3 { move-column-to-workspace 6; }
      Mod+Shift+4 { move-column-to-workspace 7; }
      Mod+Shift+5 { move-column-to-workspace 8; }
      Mod+Shift+6 { move-column-to-workspace 9; }
      Mod+Shift+7 { move-column-to-workspace 10; }
      Mod+Shift+8 { move-column-to-workspace 11; }
      Mod+Shift+9 { move-column-to-workspace 12; }
      Mod+Shift+0 { move-column-to-workspace 13; }

      Mod+X { focus-workspace "terminal"; }
      Mod+Shift+X { move-column-to-workspace "terminal"; }

      Mod+V { focus-workspace "browser"; }
      Mod+Shift+V { move-column-to-workspace "browser"; }

      Mod+C { focus-workspace "comms"; }
      Mod+Shift+C { move-column-to-workspace "comms"; }

      // Media keys (allow when locked)
      XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
      XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
      XF86AudioPause allow-when-locked=true { spawn "playerctl" "play-pause"; }
      XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
      XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
      XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "s" "10%+"; }
      XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "s" "10%-"; }
    }
  '';
}
