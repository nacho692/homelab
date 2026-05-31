{ ... }:
{
  imports = [
    ../shared
    ./livesync-bridge.nix
    ./claude-telegram-bridge.nix
  ];

  home.username = "skynet";
  home.homeDirectory = "/home/skynet";
}
