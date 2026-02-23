inputs: self: super: {
  serve = inputs.serve.packages.${self.stdenv.hostPlatform.system}.default;
  status = inputs.status.packages.${self.stdenv.hostPlatform.system}.default;
  ghostty = inputs.ghostty.packages.${self.stdenv.hostPlatform.system}.default;

  # Add our bundled npm packages
  npm-global = self.callPackage ./npm-global {};

  # pnpm has intermittent issues on ZFS when linking many files at once. We can
  # just try multiple times and wait until we succeed, but setting the
  # package-import-method to hardlink for packages with this issue works fine.
  #
  # https://github.com/pnpm/pnpm/issues/4161
  # https://github.com/pnpm/pnpm/issues/7024
  # https://github.com/pnpm/pnpm/issues/5803
  pnpm_10 =
    super.pnpm_10
    // {
      fetchDeps = args: let
        # Extract user-provided prePnpmInstall if any
        packagePreInstall = args.prePnpmInstall or "";

        # Hardlink all packages
        preInstall = ''
          echo "→ pnpm overlay: setting package-import-method to hardlink"
          pnpm config set package-import-method hardlink
        '';

        # Combine global and user-defined prePnpmInstall
        combinedPre = ''
          ${preInstall}
          ${packagePreInstall}
        '';
      in
        super.pnpm_10.fetchDeps (args // {prePnpmInstall = combinedPre;});

      configHook =
        super.makeSetupHook {
          name = "pnpm-config-hook";
          propagatedBuildInputs = [super.pnpm_10];
        } (super.writeScript "pnpm-config-hook.sh" ''
          local patched="$(cat ${super.pnpm_10.configHook}/nix-support/setup-hook \
            | sed '/pnpm config set store-dir/a pnpm config set package-import-method hardlink' \
          )"

          eval "$patched"
        '');
    };

  # Extract codelldb from the vscode extension
  codelldb = self.writeShellScriptBin "codelldb" ''
    exec -a $0 ${self.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $@
  '';

  wingthing = self.stdenv.mkDerivation {
    pname = "wingthing";
    version = "0.109.0";

    src = self.fetchurl {
      url = "https://github.com/ehrlich-b/wingthing/releases/download/v0.109.0/wt-linux-amd64";
      hash = "sha256-EweoQtH6AfPB0QngApQ8yVflGZOh4UVGWFGjbQxUhD4=";
    };

    dontUnpack = true;

    nativeBuildInputs = [self.autoPatchelfHook];

    installPhase = ''
      install -Dm755 $src $out/bin/wt
    '';
  };

  # Add nix-ai-tools packages to pkgs
  llm-agents = inputs.llm-agents.packages.${self.stdenv.hostPlatform.system};
}
