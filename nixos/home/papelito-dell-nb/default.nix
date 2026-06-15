{ pkgs, ... }:

{
  imports = [
    ../shared
    # ../shared/hyprland.nix
    ../shared/niri.nix
  ];

  home.packages = with pkgs; [
    libnotify
    libreoffice-qt
    swww
    fuzzel
    ansible
  ];
}
