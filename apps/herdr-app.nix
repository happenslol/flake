{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  libxcb,
  libxkbcommon,
  libglvnd,
  vulkan-loader,
  wayland,
  herdr-core,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-app";
  version = "0.1.9";

  src = fetchurl {
    url = "https://releases.herdr.dev/app/${finalAttrs.version}/herdr-app-linux-x86_64.tar.gz";
    hash = "sha256-2m97QPbEFsW03vjbz4t2Z30Cvk9LRdBqTWWHZoUOC0U=";
  };

  sourceRoot = "herdr-app";

  nativeBuildInputs = [autoPatchelfHook makeWrapper copyDesktopItems];
  buildInputs = [stdenv.cc.cc.lib libxcb libxkbcommon];

  # GPUI/wgpu dlopens these at runtime (Vulkan, EGL, Wayland).
  runtimeDependencies = map lib.getLib [libglvnd vulkan-loader wayland];

  # The app updates itself in place when it finds herdr-app.svg next to its
  # binary. Keeping the icon out of bin/ turns that off.
  installPhase = ''
    runHook preInstall

    install -Dm755 herdr-app $out/bin/herdr-app
    install -Dm644 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg

    # Fall back to our herdr-core when PATH has none.
    wrapProgram $out/bin/herdr-app --suffix PATH : ${lib.makeBinPath [herdr-core]}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "herdr-app";
      desktopName = "Herdr";
      comment = "Terminals and coding agents that keep running";
      exec = "herdr-app";
      icon = "herdr-app";
      categories = ["Development"];
      startupWMClass = "herdr-app";
    })
  ];

  meta = {
    description = "Native app for running Claude Code, Codex and other coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "herdr-app";
    platforms = ["x86_64-linux"];
  };
})
