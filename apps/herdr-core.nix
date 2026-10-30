{
  lib,
  stdenv,
  fetchurl,
}:
# The server that runs Herdr's terminals and agents. Static binary, so no
# patching. It sees its own /nix/store path and refuses to self-update,
# telling you to bump it here instead.
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-core";
  version = "0.1.14";

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${finalAttrs.version}/herdr-core-linux-x86_64.tar.gz";
    hash = "sha256-6dur3q0M4M495RtvVMyVSe/tu0Gy+ESLaTKrDRRCND4=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-core $out/bin/herdr-core
    ln -s herdr-core $out/bin/hc
    runHook postInstall
  '';

  meta = {
    description = "Background server that keeps Herdr's terminals and coding agents running";
    homepage = "https://github.com/herdrdev/herdr-core";
    license = lib.licenses.asl20;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "hc";
    platforms = ["x86_64-linux"];
  };
})
