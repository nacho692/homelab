{ pkgs, lib, ... }:

{
  services.xserver.enable = true;

  services.displayManager.gdm = {
    enable = true;
  };

  programs = {
    # hyprland = {
    #   enable = true;
    #   xwayland.enable = true;
    # };
    niri.enable = true;
  };

  environment.systemPackages = with pkgs; [
    waybar
    nautilus
    kitty
    walker
    hyprpaper
    seahorse
    nwg-look
    hyprshot
    wl-clip-persist
    wl-clipboard
    brightnessctl
    playerctl
    networkmanagerapplet
    pavucontrol
    gnome-calculator
    gnome-text-editor
    swaybg
    xwayland-satellite
  ];

  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  services.gvfs.enable = true;
  fonts.packages = with pkgs; [
    font-awesome
  ];
  services.power-profiles-daemon.enable = true;
}
