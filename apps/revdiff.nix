{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "revdiff";
  version = "1.11.1";
  sourceRoot = ".";
  nativeBuildInputs = [autoPatchelfHook];
  installPhase = ''
    install -Dm755 revdiff $out/bin/revdiff
  '';
  src = fetchurl {
    url = "https://github.com/umputun/revdiff/releases/download/v${version}/revdiff_${version}_linux_amd64.tar.gz";
    hash = "sha256-eVimvvcjJn/tGLC+lkdrt2djav6WYzjtfjcMClBv1Uw=";
  };
}
