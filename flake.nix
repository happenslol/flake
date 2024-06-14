{
  description = "system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
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

    grub2-theme = {
      url = "github:happenslol/grub2-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wezterm = {
      url = "github:wez/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    atuin = {
      url = "github:happenslol/atuin/fork";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    nix-index-database,
    ...
  }: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    stateVersion = "23.11";
    username = "happens";

    overlays = [
      inputs.nixpkgs-wayland.overlay
      inputs.hyprland-contrib.overlays.default
    ];

    pkgs = import nixpkgs {
      inherit system;
      overlays = overlays;
      config = {
        allowUnfree = true;
        allowBroken = true;

        permittedInsecurePackages = [
          "electron-25.9.0"
        ];
      };
    };

    mkHost = hostname:
      lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs stateVersion hostname username;};

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
              extraSpecialArgs = {
                inherit
                  inputs
                  stateVersion
                  hostname
                  system
                  username
                  ;
              };

              users.${username}.imports = [./home.nix];
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
