# pnpm has intermittent issues on ZFS when linking many files at once. We can
# just try multiple times and wait until we succeed, but setting the
# package-import-method to hardlink for all packages works as well.
#
# https://github.com/pnpm/pnpm/issues/4161
# https://github.com/pnpm/pnpm/issues/7024
# https://github.com/pnpm/pnpm/issues/5803
self: super: {
  pnpm =
    super.pnpm
    // {
      fetchDeps = origArgs: let
        # Extract user-provided prePnpmInstall if any
        packagePreInstall = origArgs.prePnpmInstall or "";

        # Your global logic
        preInstall = ''
          echo "→ Global: setting package-import-method to hardlink"
          pnpm config set package-import-method hardlink
        '';

        # Combine global and user-defined prePnpmInstall
        combinedPre = ''
          ${preInstall}
          ${packagePreInstall}
        '';
      in
        super.pnpm.fetchDeps (origArgs // {prePnpmInstall = combinedPre;});
    };
}
