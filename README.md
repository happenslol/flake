# NixOS system configuration

Non-obvious things this does:

- Global commands with ,flake
- Install global npm packages at specific versions using a custom nix package
- Change pnpm config for all nixpkgs packages (needed due to a ZFS/pnpm bug)
- Force 1password specifically to X11
- Allow dynamic binary execution with nix-ld
- Install codelldb for rust debugging without vscode
