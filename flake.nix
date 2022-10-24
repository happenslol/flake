{
  description = "system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, home-manager, nixos-hardware, ... }:
  let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.allowBroken = true;
    };

  in {
    nixosConfigurations = {
      mira = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          # TODO: Marked as broken currently
          nixos-hardware.nixosModules.framework-12th-gen-intel

          ./common.nix
          ./lib/sway.nix
          ./lib/greetd.nix
          ./lib/zfs.nix
          ./mira/configuration.nix

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.happens = import ./home.nix;
          }
        ];
      };
    };
  };
}
