{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "transcoder";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.interfaces.enp2s0.ipv4.addresses = [{
    address = "10.0.0.11";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.0.0.1";

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  # Configure console keymap
  console.keyMap = "us-acentos";

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # NFS client support
  boot.supportedFilesystems = [ "nfs" ];

  fileSystems."/mnt/raid" = {
    device = "10.0.0.2:/mnt/raid";
    fsType = "nfs";
    options = [ "nfsvers=4" "_netdev" "x-systemd.automount" "x-systemd.mount-timeout=30" ];
  };

  fileSystems."/media/data" = {
    device = "10.0.0.2:/media/data";
    fsType = "nfs";
    options = [ "nfsvers=4" "_netdev" "x-systemd.automount" "x-systemd.mount-timeout=30" ];
  };

  # Ensure Docker starts only after NFS mounts are available
  systemd.services.docker = {
    after = [ "mnt-raid.mount" "media-data.mount" ];
    requires = [ "mnt-raid.mount" "media-data.mount" ];
  };

  users.users.skynet = {
    isNormalUser = true;
    description = "Ignacio";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # Tailscale
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  # Enable docker
  virtualisation.docker.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    dnsutils
    python3
    bc
    curl
    jq
    smartmontools
  ];

  # SMART self-tests
  services.smartd = {
    enable = true;
    devices = [
      { device = "/dev/sda"; options = "-a -s (S/../../7/02|L/../../1/03)"; }
    ];
    notifications.mail.enable = false;
  };

  # Monitoring collection timer
  systemd.services.monitoring = {
    description = "Homelab monitoring collection";
    after = [ "network-online.target" "mnt-raid.mount" ];
    wants = [ "network-online.target" ];
    requires = [ "mnt-raid.mount" ];
    path = with pkgs; [ bash coreutils gawk bc curl jq smartmontools procps ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/opt/monitoring/run-all.sh";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.monitoring = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      RandomizedDelaySec = 30;
      Persistent = true;
    };
  };

  # For non nixOS binaries (e.g: uv python installs)
  programs.nix-ld.enable = true;

  # Enable SSH
  services.openssh.enable = true;

  system.stateVersion = "25.11";
}
