{ pkgs, ... }:

let
  useCursorAppImage = true;
  cursorApp = import ../shared/cursor.nix { inherit pkgs; };
  cursorPackage = if useCursorAppImage then cursorApp else pkgs.code-cursor-fhs;
in
{
  imports = [
    ../shared
    ../shared/hyprland.nix
    ../shared/niri.nix
  ];

  home.packages = with pkgs; [
    gopls
    cursorPackage
    awscli2
    ssm-session-manager-plugin
    jetbrains.datagrip
    slack
    notion-app-enhanced
    libnotify
    libreoffice-qt
    bitwarden-cli
    swww
  ];
}
