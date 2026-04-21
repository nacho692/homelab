{ pkgs, lib, ... }:

{
  # -----------------------------------------------------------------------
  # Disk layout (applied at install time by disko, via nixos-anywhere)
  # -----------------------------------------------------------------------
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  # -----------------------------------------------------------------------
  # Boot + networking
  # -----------------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "vm-network";
  networking.useDHCP = true;

  # AdGuard needs port 53 (DNS). systemd-resolved also listens on 53 by default
  # and would conflict. Disable it and let AdGuard own the port.
  services.resolved.enable = false;

  # Web UI (3000) + DNS (53) open on the firewall.
  networking.firewall.allowedTCPPorts = [ 53 3000 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  # -----------------------------------------------------------------------
  # AdGuard Home — Pi-hole-style DNS + ad blocking with a web UI.
  # Set declaratively; no initial-setup wizard needed.
  # -----------------------------------------------------------------------
  services.adguardhome = {
    enable = true;
    openFirewall = true;
    mutableSettings = false;
    settings = {
      users = [{
        # Default login: admin / admin (change later, stored as bcrypt hash;
        # bake real hash in before exposing on real LAN).
        name = "admin";
        # bcrypt of "admin" — replace for production.
        password = "$2y$10$FrLnIdaMUlJQLkv3OKOQNOZD9MYMltuf2DRD8SJnPNnkZjbBB3qfq";
      }];
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [
          "1.1.1.1"
          "1.0.0.1"
          "9.9.9.9"
        ];
        bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
      };
      http = {
        address = "0.0.0.0:3000";
      };
      filters = [
        {
          enabled = true;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          id = 1;
        }
      ];
    };
  };

  # -----------------------------------------------------------------------
  # SSH access for the builder
  # -----------------------------------------------------------------------
  services.openssh = {
    enable = true;
    # Keep root login open for nixos-anywhere / emergency fixes; day-to-day
    # use goes through the `skynet` user below.
    settings.PermitRootLogin = "prohibit-password";
  };

  # Primary admin user on every homelab host — matches the ansible-era
  # convention. Member of wheel (passwordless sudo so comin / nixos-rebuild
  # can activate), with the same SSH key installed on root.
  users.users.skynet = {
    isNormalUser = true;
    description = "Homelab admin";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0tqObUd8+w40MBVIQRhTAVRQIV0IOSmSWjrNVtczru papelito@pop-os"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0tqObUd8+w40MBVIQRhTAVRQIV0IOSmSWjrNVtczru papelito@pop-os"
  ];

  environment.etc."homelab-host".text = "vm-network (adguardhome)\n";
  environment.systemPackages = with pkgs; [ vim git curl htop dig ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # -----------------------------------------------------------------------
  # Comin — pull-based continuous deployment. Host polls the homelab repo
  # and auto-applies changes to the `main` branch. Testing: push to
  # `testing`, comin builds+switches; merge to `main` to promote.
  # -----------------------------------------------------------------------
  services.comin = {
    enable = true;
    hostname = "vm-network";
    repositorySubdir = "infra";
    remotes = [{
      name = "origin";
      url = "https://github.com/nacho692/homelab.git";
      branches.main.name = "master";
      branches.testing.name = "testing";
    }];
  };

  system.stateVersion = "25.11";
}
