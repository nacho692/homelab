{
  description = "Homelab infrastructure: declarative host configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, comin, ... }:
    let
      system = "x86_64-linux";
      mkHost = name: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          comin.nixosModules.comin
          ./hosts/${name}
        ];
      };
    in
    {
      # Install from a stock NixOS live env (USB ISO) via:
      #   nix run github:nix-community/nixos-anywhere -- --flake .#<name> root@<target-ip>
      # Once installed, comin keeps the host updated by polling the git repo.
      nixosConfigurations = {
        vm-network = mkHost "vm-network";
      };
    };
}
