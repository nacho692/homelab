{ pkgs, config, nixgl, nixpkgs-stable, ... }:

let
  nixglPackages = import "${nixgl}/default.nix" {
    inherit pkgs;
    nvidiaVersion = "580.126.18";
    nvidiaHash = "17dlk8m0j2h76g012izqbna04ka5xmwnxiql15cccr9d3hp1ny57";
  };
  pkgs-stable = import nixpkgs-stable {
    system = "x86_64-linux";
  };
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
  ];

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
  ];

  home.file.".config/kitty/kitty.conf".source = ../shared/kitty/kitty.conf;
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
    };
    templates."upmpdcli.conf" = {
      content = ''
        friendlyname = pop-os
        upnpav = 1
        openhome = 1
        avtautoplay = 1
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
