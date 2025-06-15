{
  description = "system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.05";
    nixpkgs-pinned.url = "github:NixOS/nixpkgs/63dacb46bf939521bdc93981b4cbb7ecb58427a0";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
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

    # Make sure all dependencies that use the rust overlay use the same one
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niqs = {
      url = "github:diniamo/niqspkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    serve = {
      url = "github:happenslol/serve";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pk-agent = {
      url = "github:happenslol/pk-agent";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    peek = {
      url = "github:happenslol/peek";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-pinned,
    home-manager,
    nix-index-database,
    ...
  }: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    username = "happens";

    overlays = [
      (import ./overlay.nix)
      inputs.nixpkgs-wayland.overlay
      inputs.hyprland-contrib.overlays.default
      inputs.neovim-nightly-overlay.overlays.default
    ];

    pkgs = import nixpkgs {
      inherit system;
      overlays = overlays;
      config = {
        allowUnfree = true;
        allowBroken = true;

        # Vesktop currently depends on an old electron version
        permittedInsecurePackages = ["electron-33.4.11"];
      };
    };

    niqs = inputs.niqs.packages."${system}";

    pkgs-stable = import nixpkgs-stable {inherit system;};
    pkgs-pinned = import nixpkgs-pinned {inherit system;};

    mkHost = {
      hostname,
      stateVersion,
    }: (lib.nixosSystem {
      inherit system pkgs;
      specialArgs = {inherit inputs stateVersion hostname username system pkgs-stable pkgs-pinned niqs;};

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
            extraSpecialArgs = {inherit inputs stateVersion hostname system username niqs pkgs-stable;};

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
