{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libxcb,
  libxkbcommon,
  libglvnd,
  vulkan-loader,
  wayland,
  unixodbc,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dbdelve";
  version = "0.7.1";

  src = fetchurl {
    url = "https://github.com/ShayanAbbas1/dbdelve/releases/download/v${finalAttrs.version}/dbdelve-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-sKKoMF97jMN/c7JluzRn+NbKQm+VmqrahDFCR4SFQ4w=";
  };

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib libxcb libxkbcommon unixodbc];

  # GPUI/wgpu dlopens these at runtime (Vulkan, EGL, Wayland).
  runtimeDependencies = map lib.getLib [libglvnd vulkan-loader wayland];

  # dbdelve looks for bundled plugins in plugins/ next to its real executable,
  # so the binary and the ODBC bridge live together in libexec.
  installPhase = ''
    runHook preInstall

    install -Dm755 dbdelve $out/libexec/dbdelve/dbdelve
    cp -R plugins $out/libexec/dbdelve/plugins
    mkdir -p $out/bin
    ln -s $out/libexec/dbdelve/dbdelve $out/bin/dbdelve

    install -Dm644 dbdelve.desktop $out/share/applications/dbdelve.desktop
    for size in 16 32 64 128 256 512; do
      install -Dm644 icons/dbdelve-$size.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/dbdelve.png
    done

    runHook postInstall
  '';

  meta = {
    description = "Fast, native, multi-engine database client";
    homepage = "https://dbdelve.github.io";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "dbdelve";
    platforms = ["x86_64-linux"];
  };
})
