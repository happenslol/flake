{
  description = "system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    grub2-themes = {
      url = "github:vinceliuice/grub2-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, home-manager, ... }:
  let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    stateVersion = "22.11";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.allowBroken = true;
    };

    customNodePackages = pkgs.callPackage ./node-packages {
      inherit system pkgs;
      nodejs = pkgs."nodejs-14_x";
    };

    mkHost = hostname:
      lib.nixosSystem {
        inherit system pkgs;
        specialArgs = { inherit inputs stateVersion hostname; };

        modules = [
          ({ ... }: { nixpkgs.overlays = [ inputs.nixpkgs-wayland.overlay ]; })
          (./. + "/hosts/${hostname}/hardware-configuration.nix")
          (./. + "/hosts/${hostname}/configuration.nix")
          ./common

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs stateVersion hostname customNodePackages; };
              users.happens.imports = [ ./home.nix (./. + "/hosts/${hostname}/home.nix") ];
            };
          }
        ];
      };

  in {
    nixosConfigurations = {
      mira = mkHost "mira";
      roe2 = mkHost "roe2";
    };
  };
}
