{
  description = "system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    serve = {
      url = "github:happenslol/serve";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    status.url = "github:happenslol/status";
    ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    nix-index-database,
    nixpkgs-wayland,
    neovim-nightly-overlay,
    ...
  }: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    username = "happens";

    overlays = [
      (import ./overlay.nix inputs)
      nixpkgs-wayland.overlay
      neovim-nightly-overlay.overlays.default
    ];

    pkgs = import nixpkgs {
      inherit system;
      overlays = overlays;
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };

    mkHost = {
      hostname,
      stateVersion,
    }: let
      specialArgs = {inherit inputs stateVersion hostname username system;};
    in (lib.nixosSystem {
      inherit system pkgs specialArgs;

      modules = [
        nix-index-database.nixosModules.nix-index
        ./system.nix
        (./. + "/hosts/${hostname}/hardware-configuration.nix")
        (./. + "/hosts/${hostname}/configuration.nix")

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = specialArgs;

            users.${username} = import ./home.nix;
          };
        }
      ];
    });
  in {
    nixosConfigurations = {
      mira = mkHost {
        hostname = "mira";
        stateVersion = "24.11";
      };
      roe2 = mkHost {
        hostname = "roe2";
        stateVersion = "24.11";
      };
      hei = mkHost {
        hostname = "hei";
        stateVersion = "24.11";
      };
    };

    devShells.${system} = import ./devshells.nix pkgs;
  };
}
