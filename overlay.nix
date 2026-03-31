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

  fence = self.stdenv.mkDerivation rec {
    pname = "fence";
    version = "0.1.39";
    sourceRoot = ".";
    nativeBuildInputs = [self.autoPatchelfHook self.makeWrapper];
    installPhase = ''
      install -Dm755 fence $out/bin/fence
      wrapProgram $out/bin/fence --prefix PATH : ${self.lib.makeBinPath [self.socat self.bubblewrap self.bpftrace]}
    '';
    src = self.fetchurl {
      url = "https://github.com/Use-Tusk/fence/releases/download/v${version}/fence_${version}_Linux_x86_64.tar.gz";
      hash = "sha256-U3Ik7PXF6or05SZOJmSkRVBgNcgeD8sJ8v8pa0FDR94=";
    };
  };

  # The Nerd Font patcher changes hhea descent/lineGap, shifting the baseline
  # up. This restores the original Iosevka Term values so glyphs sit correctly.
  nerd-fonts = super.nerd-fonts // {
    iosevka-term = super.nerd-fonts.iosevka-term.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [self.python3Packages.fonttools];
      postFixup = (old.postFixup or "") + ''
        find $out -name '*.ttf' | while read f; do
          python3 -c "
from fontTools.ttLib import TTFont
font = TTFont('$f')
font['hhea'].descent = -215
font['hhea'].lineGap = 70
font.save('$f')
"
        done
      '';
    });
  };

  # Add nix-ai-tools packages to pkgs
  llm-agents = inputs.llm-agents.packages.${self.stdenv.hostPlatform.system};
}
