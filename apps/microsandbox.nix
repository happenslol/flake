{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libcap_ng,
  libgcc,
  crun,
  nftables,
}:
stdenv.mkDerivation rec {
  pname = "microsandbox";
  version = "0.6.0";

  src = fetchurl {
    url = "https://github.com/superradcompany/microsandbox/releases/download/v${version}/microsandbox-linux-x86_64.tar.gz";
    hash = "sha256-ecy56dAThkCWVnHW79J/2yDR/p+R2tGHejIxm+pyZ5k=";
  };

  # The release bundle contains the `msb` CLI plus the bundled libkrunfw
  # shared library it dlopens. libcap-ng is a real DT_NEEDED of the msb
  # binary, so it must be on the RPATH (autoPatchelf resolves it from
  # buildInputs). msb locates libkrunfw via the MSB_LIBKRUNFW_PATH env var.
  # The archive unpacks its files straight into the cwd (no top dir).
  sourceRoot = ".";
  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  buildInputs = [libcap_ng libgcc];

  installPhase = ''
    # msb CLI
    install -Dm755 msb $out/bin/msb
    ln -s msb $out/bin/microsandbox

    # Bundled libkrunfw (msb dlopens it; ship the SONAME symlinks the
    # upstream installer creates so bare-name + ABI lookups both resolve).
    install -Dm644 libkrunfw.so.5.2.1 $out/lib/libkrunfw.so.5.2.1
    ln -sf libkrunfw.so.5.2.1 $out/lib/libkrunfw.so.5
    ln -sf libkrunfw.so.5   $out/lib/libkrunfw.so

    # Point msb at the store copy of libkrunfw so it never tries to download
    # one into ~/.microsandbox on first sandbox boot. crun runs OCI images,
    # nftables backs the optional TLS-redirect / egress policy path.
    wrapProgram $out/bin/msb \
      --set MSB_LIBKRUNFW_PATH $out/lib/libkrunfw.so.5.2.1 \
      --prefix PATH : ${lib.makeBinPath [crun nftables]}
  '';
}
