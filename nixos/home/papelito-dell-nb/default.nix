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
    awww
    fuzzel
    ansible
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [ "erlang" "gleam" ];
  };
}
