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
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
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
      url = "github:happenslol/wezterm/fork";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    atuin = {
      url = "github:happenslol/atuin/fork";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dream2nix.url = "github:nix-community/dream2nix";
    prettierd = {
      url = "github:fsouza/prettierd/main";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    stateVersion = "22.11";
    username = "happens";

    overlays = [
      inputs.nixpkgs-wayland.overlay
      inputs.hyprpicker.overlays.default
      inputs.hyprland-contrib.overlays.default
    ];

    pkgs = import nixpkgs {
      inherit system;
      overlays = overlays;
      config = {
        allowUnfree = true;
        allowBroken = true;

        permittedInsecurePackages = [
          "electron-21.4.0"
        ];
      };
    };

    mkHost = hostname:
      lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit inputs stateVersion hostname;};

        modules = [
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
