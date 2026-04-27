{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  socat,
  bubblewrap,
  bpftrace,
}:
stdenv.mkDerivation rec {
  pname = "fence";
  version = "0.1.39";
  sourceRoot = ".";
  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  installPhase = ''
    install -Dm755 fence $out/bin/fence
    wrapProgram $out/bin/fence --prefix PATH : ${lib.makeBinPath [socat bubblewrap bpftrace]}
  '';
  src = fetchurl {
    url = "https://github.com/Use-Tusk/fence/releases/download/v${version}/fence_${version}_Linux_x86_64.tar.gz";
    hash = "sha256-U3Ik7PXF6or05SZOJmSkRVBgNcgeD8sJ8v8pa0FDR94=";
  };
}
