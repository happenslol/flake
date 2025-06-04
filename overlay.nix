self: super: {
  # pnpm has intermittent issues on ZFS when linking many files at once. We can
  # just try multiple times and wait until we succeed, but setting the
  # package-import-method to hardlink for all packages works as well.
  #
  # https://github.com/pnpm/pnpm/issues/4161
  # https://github.com/pnpm/pnpm/issues/7024
  # https://github.com/pnpm/pnpm/issues/5803
  pnpm =
    super.pnpm
    // {
      fetchDeps = origArgs: let
        # Extract user-provided prePnpmInstall if any
        packagePreInstall = origArgs.prePnpmInstall or "";

        # Hardlink all packages
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

  # 1password has a lot of problems when running under wayland (broken copy/paste
  # being the most egregious). Until that issue is resolved, we'll have to deal
  # with a blurry GUI.
  _1password-gui = super._1password-gui.overrideAttrs (_: {
    postFixup = "wrapProgram $out/bin/1password --set ELECTRON_OZONE_PLATFORM_HINT x11";
  });

  # Configure vesktop
  vesktop = super.vesktop.override {
    electron = self.electron_33;
    withTTS = false;
    withMiddleClickScroll = true;
  };
}
