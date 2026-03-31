Personal NixOS flake managing three machines (mira, roe2, hei) with shared system/home configuration, custom modules, and dotfiles.

## Architecture

**`flake.nix`** defines inputs (nixpkgs unstable, home-manager, nixos-hardware, sops-nix, etc.) and uses a `mkHost` helper to build three `nixosConfigurations`. Each host gets the shared config plus host-specific overrides via `specialArgs { hostname }`.

**Shared configuration layers:**
- `system.nix` — NixOS system config (boot, services, Wayland/Sway/Niri, audio, gaming, fonts, sops secrets)
- `home.nix` — home-manager config (dotfile symlinks from `config/` and `hosts/{hostname}/config/`, programs, services)
- `packages.nix` — all user-level packages
- `overlay.nix` — package patches and custom packages
- `ld.nix` — nix-ld library list for running non-nix binaries
- `devshells.nix` — reusable devshells

**Per-host (`hosts/{name}/`):**
- `configuration.nix` — host-specific NixOS config (hardware modules, core count, services)
- `hardware-configuration.nix` — filesystems, ZFS pools, boot
- `config/` — host-specific dotfiles (window manager configs, etc.)

**Notable host differences:**
- `mira` — Framework laptop (Intel), bluetooth, brightness control
- `roe2` — AMD workstation running media services (Transmission, Radarr, Sonarr, Jellyfin) behind PIA VPN in a WireGuard network namespace
- `hei` — AMD desktop, simpler config

**Custom modules (`modules/`):**
- `pia-vpn.nix` — PIA VPN module with WireGuard, network namespace isolation, port forwarding, sops-nix credentials

**Secrets:** sops-nix with age encryption, per-host SSH ed25519 keys (`.sops.yaml`), secrets in `secrets.json`.

**Dotfiles:** `config/` contains all user dotfiles (nvim, zsh, kitty, sway, niri, git, etc.), symlinked into `~/.config` via home-manager's `xdg.configFile`.

## Workflows

- After making changes, always run `just format` to format the code.
- Never attempt to apply the configuration yourself, delegate this to the user.
