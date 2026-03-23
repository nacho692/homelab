{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./hyprland.nix
      ./dell-nb.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dell-nb";

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  boot.kernelParams = ["resume_offset=12111872"];
  boot.resumeDevice = "/dev/disk/by-uuid/15b8bf8d-bcf8-42d9-b7df-caf0b24b157d";
  powerManagement.enable = true;

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32*1024;
  }];

  users.users.papelito = {
    isNormalUser = true;
    description = "Ignacio";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # Enable appimage
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  # Enable automatic login for the user.
  services.displayManager.autoLogin.user = "papelito";
  services.displayManager.autoLogin.enable = true;
  services.displayManager.defaultSession = "niri";

  # GDM auto-login workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Disable firewall
  networking.firewall.enable = false;

  # Tailscale
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  # Bluetooth gui
  services.blueman.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Steam
  programs.steam.enable = true;

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
  ];

  # For non nixOS binaries (e.g: uv python installs)
  programs.nix-ld.enable = true;


  services.udev.extraRules = ''
  '';

  system.stateVersion = "25.05";
}
