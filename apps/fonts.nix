{
  stdenv,
  lib,
  fetchurl,
  fetchzip,
  unzip,
}: {
  dm-sans = stdenv.mkDerivation {
    pname = "dm-sans";
    version = "0-unstable-2026-05-21";
    srcs = [
      (fetchurl {
        # Google's DM Sans (OFL), pinned to a google/fonts commit so the
        # unversioned upstream path doesn't drift. Overrides nixpkgs' dm-sans,
        # which is DeepMind Sans (a different font).
        url = "https://raw.githubusercontent.com/google/fonts/5b35b7208dd4100571326fdf37f030b32a524232/ofl/dmsans/DMSans%5Bopsz%2Cwght%5D.ttf";
        name = "DMSans-Roman.ttf";
        hash = "sha256-jNCNl+icJNCqku3S8PTI7mGV7um3yfFUhlpYsC8MHA0=";
      })
      (fetchurl {
        url = "https://raw.githubusercontent.com/google/fonts/5b35b7208dd4100571326fdf37f030b32a524232/ofl/dmsans/DMSans-Italic%5Bopsz%2Cwght%5D.ttf";
        name = "DMSans-Italic.ttf";
        hash = "sha256-IiWcDMgjciG4D0THa6jTbmvOPNpyd59bJ3NkPUmXIK4=";
      })
    ];
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 $srcs -t $out/share/fonts/truetype
      runHook postInstall
    '';
    meta = {
      description = "Google DM Sans variable font";
      license = lib.licenses.ofl;
      platforms = lib.platforms.all;
    };
  };

  mona-sans = stdenv.mkDerivation (final: {
    pname = "mona-sans";
    version = "2.0.27";
    src = fetchurl {
      url = "https://github.com/github/mona-sans/releases/download/v${final.version}/mona-sans-variable-v${final.version}.zip";
      hash = "sha256-qVEnVQspV/+EzWNtRTKyJ93DPTSFCCQ3+ieBbvHQZuw=";
    };
    nativeBuildInputs = [unzip];
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm644 fonts/variable/*.ttf -t $out/share/fonts/truetype
      runHook postInstall
    '';
    meta = {
      description = "Mona Sans variable font by GitHub";
      license = lib.licenses.ofl;
      platforms = lib.platforms.all;
    };
  });

  satoshi = stdenv.mkDerivation {
    pname = "satoshi";
    version = "1.0";
    src = fetchzip {
      # Fontshare serves the whole family as a zip; the asset path is not
      # versioned, so the hash pins a specific snapshot.
      url = "https://api.fontshare.com/v2/fonts/download/satoshi";
      extension = "zip";
      hash = "sha256-hEzcNcIWJNAoO3F7uhZjj8wVoQwDpNQ7GAQzxchYtc8=";
    };
    installPhase = ''
      runHook preInstall
      install -Dm644 Fonts/TTF/*.ttf -t $out/share/fonts/truetype
      install -Dm644 Fonts/OTF/*.otf -t $out/share/fonts/opentype
      runHook postInstall
    '';
    meta = {
      description = "Satoshi font family by Fontshare";
      license = lib.licenses.unfree;
      platforms = lib.platforms.all;
    };
  };
}
