{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libgcc,
  e2fsprogs,
  crun,
}:
stdenv.mkDerivation rec {
  pname = "smolvm";
  version = "1.2.5";

  src = fetchurl {
    url = "https://github.com/smol-machines/smolvm/releases/download/v${version}/smolvm-${version}-linux-x86_64.tar.gz";
    hash = "sha256-t/YkDKPZe0Lm9v5u6HysN0TuUvlReEeuBrZffSnp34E=";
  };

  # The release ships a self-contained directory: a `smolvm` bash wrapper that
  # resolves its own location (following symlinks), points LD_LIBRARY_PATH at
  # the bundled `lib/` (libkrun.so + libkrunfw.so), and execs `smolvm-bin`
  # alongside the agent-rootfs, init.krun and ext4 templates. Keep that layout
  # intact under libexec/ and expose the wrapper as bin/smolvm.
  sourceRoot = "smolvm-${version}-linux-x86_64";

  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  buildInputs = [libgcc]; # smolvm-bin + bundled libkrun.so link against libgcc_s

  # Only patch the host-side ELF files. The bundled agent-rootfs/ runs inside
  # the guest VM (musl); autoPatchelf must not rewrite its interpreter/RPATH or
  # the guest binaries would point at nix-store paths that don't exist there.
  dontAutoPatchelf = true;

  installPhase = ''
    mkdir -p $out/libexec/smolvm
    cp -r . $out/libexec/smolvm/

    # Patch only the host runtime binary and its bundled libs.
    autoPatchelf $out/libexec/smolvm/smolvm-bin $out/libexec/smolvm/lib

    mkdir -p $out/bin
    makeWrapper $out/libexec/smolvm/smolvm $out/bin/smolvm \
      --prefix PATH : ${lib.makeBinPath [e2fsprogs crun]}
  '';
}
