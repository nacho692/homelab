{ ... }:
{
  imports = [
    ../shared
    ./livesync-bridge.nix
  ];

  home.username = "skynet";
  home.homeDirectory = "/home/skynet";
}
