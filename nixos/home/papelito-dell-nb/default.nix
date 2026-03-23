{ pkgs, ... }:

{
  imports = [
    ../shared
    ../shared/hyprland.nix
    ../shared/niri.nix
  ];

  home.packages = with pkgs; [
    awscli2
    ssm-session-manager-plugin
    jetbrains.datagrip
    libnotify
    libreoffice-qt
    bitwarden-cli
    swww
    fuzzel
    ansible
  ];
}
