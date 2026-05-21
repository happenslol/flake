{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "revdiff";
  version = "1.3.0";
  sourceRoot = ".";
  nativeBuildInputs = [autoPatchelfHook];
  installPhase = ''
    install -Dm755 revdiff $out/bin/revdiff
  '';
  src = fetchurl {
    url = "https://github.com/umputun/revdiff/releases/download/v${version}/revdiff_${version}_linux_amd64.tar.gz";
    hash = "sha256-XM29vRhL7mlyGdwtDDpS5vRiCc8lyhAofBgBTz8Nm9g=";
  };
}
