{ pkgs, config, nixgl, nixpkgs-stable, cos-cli, ... }:

let
  nixglPackages = import "${nixgl}/default.nix" {
    inherit pkgs;
    nvidiaVersion = "580.126.18";
    nvidiaHash = "17dlk8m0j2h76g012izqbna04ka5xmwnxiql15cccr9d3hp1ny57";
  };
  pkgs-stable = import nixpkgs-stable {
    system = "x86_64-linux";
  };
  homeassistant-config = "${config.home.homeDirectory}/.config/homeassistant";
  homeassistant-setup = pkgs.writeShellScript "homeassistant-setup" ''
    set -e
    CONFIG="${homeassistant-config}"
    mkdir -p "$CONFIG/custom_components" "$CONFIG/themes"

    install_integration() {
      local name=$1 repo=$2 version=$3
      if [ ! -d "$CONFIG/custom_components/$name" ]; then
        local tmp=$(mktemp -d)
        ${pkgs.curl}/bin/curl -sL "https://github.com/$repo/archive/refs/tags/$version.tar.gz" | tar xz -C "$tmp"
        cp -r "$tmp"/*/custom_components/"$name" "$CONFIG/custom_components/"
        rm -rf "$tmp"
      fi
    }

    install_integration remote_homeassistant custom-components/remote_homeassistant 4.6
    install_integration localtuya rospogrigio/localtuya v5.2.5

    # Ensure configuration.yaml exists with defaults
    if [ ! -f "$CONFIG/configuration.yaml" ]; then
      cat > "$CONFIG/configuration.yaml" << 'YAML'
default_config:

frontend:
  themes: !include_dir_merge_named themes

automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml

remote_homeassistant:
  instances: []
YAML
    fi

    touch "$CONFIG/automations.yaml" "$CONFIG/scripts.yaml" "$CONFIG/scenes.yaml"
  '';
in
{
  imports = [
    ../shared
  ];

  targets.genericLinux.nixGL = {
    packages = nixglPackages;
    defaultWrapper = "nvidiaPrime";
    installScripts = [ "nvidiaPrime" ];
  };

  home.packages = [
    (config.lib.nixGL.wrap pkgs.kitty)
    pkgs.wl-clipboard
    pkgs.mpc
    pkgs.upmpdcli
    pkgs.mpdris2-rs
    pkgs.pa-dlna-chromecast
    pkgs-stable.gupnp-tools
    pkgs.nodejs_22
    pkgs.yt-dlp
    pkgs.sops
    cos-cli.defaultPackage.x86_64-linux
  ];

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
  ];

  home.file.".config/kitty/kitty.conf".source = ../shared/kitty/kitty.conf;
  home.file.".local/bin/new-kitty-window" = {
    source = ../shared/kitty/new-kitty-window.sh;
    executable = true;
  };
  home.file.".config/environment.d/90-nix-profile.conf".text = ''
    PATH=${config.home.profileDirectory}/bin:$PATH
    XDG_DATA_DIRS=${config.home.profileDirectory}/share:$XDG_DATA_DIRS
  '';
  home.file.".config/pa-dlna/pa-dlna.conf".text = ''
    [DEFAULT]
    track_metadata = yes
  '';
  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
      audio_buffer_size "65536"
      auto_update "no"
      restore_paused "yes"
    '';
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/subsonic.yaml;
    secrets = {
      subsonic_user = { };
      subsonic_password = { };
      jellyfin_api_key = {
        sopsFile = ../../secrets/jellyfin.yaml;
      };
    };
    templates."jellyfin.conf" = {
      content = ''
        api_key = ${config.sops.placeholder.jellyfin_api_key}
        url = https://rataflix.69.net.ar
      '';
      path = "${config.home.homeDirectory}/.config/mpv-daemon/jellyfin.conf";
    };
    templates."upmpdcli.conf" = {
      content = ''
        friendlyname = pop-os
        upnpav = 1
        openhome = 1
        avtautoplay = 1
        upnpport = 49152
        pkgdatadir = ${pkgs.upmpdcli}/share/upmpdcli
        mpdhost = 127.0.0.1
        mpdport = 6600
        subsonicuser = ${config.sops.placeholder.subsonic_user}
        subsonicpassword = ${config.sops.placeholder.subsonic_password}
        subsonicbaseurl = https://ratafy.69.net.ar
        subsonicport = 443
      '';
      path = "${config.home.homeDirectory}/.config/upmpdcli/upmpdcli.conf";
    };
  };

  systemd.user.services.mpdris2 = {
    Unit = {
      Description = "MPD MPRIS bridge";
      After = [ "mpd.service" ];
    };

    Service = {
      ExecStart = "${pkgs.mpdris2-rs}/bin/mpdris2-rs";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.upmpdcli = {
    Unit = {
      Description = "UPnP/DLNA and OpenHome media renderer";
      After = [ "network-online.target" "mpd.service" "sops-nix.service" ];
      Requires = [ "mpd.service" ];
      BindsTo = [ "mpd.service" ];
      PartOf = [ "mpd.service" ];
    };
    Service = {
      ExecStartPre = "${pkgs.bash}/bin/bash -lc 'for _ in $(seq 1 20); do ${pkgs.mpc}/bin/mpc -h 127.0.0.1 -p 6600 status >/dev/null 2>&1 && exit 0; sleep 1; done; exit 1'";
      ExecStart = "${pkgs.upmpdcli}/bin/upmpdcli -c %h/.config/upmpdcli/upmpdcli.conf";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "mpd.service" ];
    };
  };

  systemd.user.services.mpv = {
    Unit = {
      Description = "MPV media player daemon";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = builtins.concatStringsSep " " [
        "/usr/bin/mpv"
        "--idle"
        "--no-terminal"
        "--input-ipc-server=/tmp/mpvsocket"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.homeassistant = {
    Unit = {
      Description = "Home Assistant local instance";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStartPre = [
        "${homeassistant-setup}"
        "-/usr/bin/docker rm -f homeassistant-local"
      ];
      ExecStart = builtins.concatStringsSep " " [
        "/usr/bin/docker run"
        "--name homeassistant-local"
        "--rm"
        "--network=host"
        "--privileged"
        "-v ${homeassistant-config}:/config"
        "-v /etc/localtime:/etc/localtime:ro"
        "-v /run/dbus:/run/dbus:ro"
        "-e TZ=America/Argentina/Buenos_Aires"
        "ghcr.io/home-assistant/home-assistant:stable"
      ];
      ExecStop = "/usr/bin/docker stop homeassistant-local";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.claude-telegram-bridge = {
    Unit = {
      Description = "Claude Telegram Bridge";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      WorkingDirectory = "${config.home.homeDirectory}/Projects/claude-telegram-bridge";
      ExecStart = "${pkgs.nodejs_22}/bin/node dist/index.js";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PATH=${pkgs.openai-whisper}/bin:${pkgs.ffmpeg}/bin:${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.pa-dlna = {
    Unit = {
      Description = "PipeWire/PulseAudio to DLNA bridge";
      After = [ "network-online.target" "pipewire-pulse.service" ];
      Wants = [ "network-online.target" "pipewire-pulse.service" ];
      Requires = [ "pipewire-pulse.service" ];
      BindsTo = [ "pipewire-pulse.service" ];
      PartOf = [ "pipewire-pulse.service" ];
    };
    Service = {
      ExecStart = "${pkgs.pa-dlna-chromecast}/bin/pa-dlna";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 15;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
