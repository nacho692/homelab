{
  description = "NixOS + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix";
    codex-cli.url = "github:sadjow/codex-cli-nix";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cos-cli = {
      url = "github:estin/cos-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-stable, home-manager, claude-code, codex-cli, nixgl, sops-nix, cos-cli, ... }:
    let
      localOverlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (python-final: python-prev: {
            libpulse = python-final.callPackage ./pkgs/python-libpulse.nix { };
            pa-dlna = python-final.callPackage ./pkgs/pa-dlna.nix { };
            pa-dlna-chromecast = python-final.callPackage ./pkgs/pa-dlna-chromecast.nix { };
            subsonic-connector = python-final.callPackage ./pkgs/subsonic-connector.nix { };
          })
        ];
        pa-dlna = final.python3Packages.pa-dlna;
        pa-dlna-chromecast = final.python3Packages.pa-dlna-chromecast;
        libnpupnp = final.callPackage ./pkgs/libnpupnp.nix { };
        libupnpp = final.callPackage ./pkgs/libupnpp.nix { };
        upmpdcli = final.callPackage ./pkgs/upmpdcli.nix { };
        mpdris2-rs = prev.mpdris2-rs.overrideAttrs (old:
          let
            newSrc = final.fetchFromGitHub {
              owner = "szclsya";
              repo = "mpdris2-rs";
              rev = "trunk";
              hash = "sha256-vNVczNW49lMzAN2p7pnzClKGp2ehQlQAikN2xZkjwwY=";
            };
          in
          {
            src = newSrc;
            cargoDeps = final.rustPlatform.fetchCargoVendor {
              src = newSrc;
              hash = "sha256-svuZN3/UTyZGQzNETRLbDi6HyKk8TGpdRFqcQhz8Wuc=";
            };
          });
      };
    in
    {
      nixosConfigurations.dell-nb = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/dell-nb/configuration.nix
        ];
      };

      nixosConfigurations.transcoder = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/transcoder/configuration.nix
        ];
      };

      homeConfigurations."papelito" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ claude-code.overlays.default codex-cli.overlays.default ];
        };
        modules = [
          ./home/shared
        ];
      };

      homeConfigurations."skynet" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ claude-code.overlays.default codex-cli.overlays.default ];
        };
        modules = [
          ./home/skynet
          sops-nix.homeManagerModules.sops
        ];
      };

      homeConfigurations."papelito@pop-os" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ claude-code.overlays.default codex-cli.overlays.default localOverlay ];
        };
        extraSpecialArgs = { inherit nixgl nixpkgs-stable cos-cli; };
        modules = [
          ./home/papelito-pop-os
          sops-nix.homeManagerModules.sops
        ];
      };

      homeConfigurations."papelito@dell-nb" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ claude-code.overlays.default codex-cli.overlays.default ];
        };
        modules = [
          ./home/papelito-dell-nb
        ];
      };

      homeConfigurations."skynet@transcoder" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ claude-code.overlays.default codex-cli.overlays.default ];
        };
        modules = [
          ./home/skynet-transcoder
        ];
      };
    };
}
