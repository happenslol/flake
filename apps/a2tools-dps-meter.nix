{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  glib-networking,
  gtk3,
  webkitgtk_4_1,
  libsoup_3,
  libpcap,
  libx11,
  libxi,
}:
# Packet capture needs CAP_NET_RAW/CAP_NET_ADMIN, which the .deb grants with
# setcap in its postinst. Store paths can't carry file capabilities, so the
# capabilities come from a security wrapper in system.nix instead.
stdenv.mkDerivation (finalAttrs: {
  pname = "a2tools-dps-meter";
  version = "2.0.50";

  src = fetchurl {
    url = "https://github.com/taengu/A2Tools-DPS-Meter/releases/download/v${finalAttrs.version}/a2tools-dps-meter_${finalAttrs.version}_amd64.deb";
    hash = "sha256-iFNtWRXCq2FMAT9rGyPubcW+c+QO4KHNPfvc4qft08M=";
  };

  nativeBuildInputs = [dpkg autoPatchelfHook wrapGAppsHook3];

  buildInputs = [
    stdenv.cc.cc.lib
    gtk3
    webkitgtk_4_1
    libsoup_3
    glib-networking
  ];

  # Loaded with dlopen at runtime: libpcap for capture, libX11/libXi for the
  # pointer position under XWayland (click-through lock).
  runtimeDependencies = map lib.getLib [libpcap libx11 libxi];

  installPhase = ''
    runHook preInstall

    # Tauri resolves its resources from `<exe dir>/../lib/<productName>`, so
    # the deb's usr/ layout has to be kept as-is.
    mkdir -p $out
    cp -r usr/* $out/

    mv "$out/share/applications/A2Tools DPS Meter.desktop" \
      $out/share/applications/a2tools-dps-meter.desktop
    substituteInPlace $out/share/applications/a2tools-dps-meter.desktop \
      --replace-fail "Categories=" "Categories=Game;Utility;"

    runHook postInstall
  '';

  meta = {
    description = "Real-time DPS overlay for AION 2";
    homepage = "https://github.com/taengu/A2Tools-DPS-Meter";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "a2tools-dps-meter";
    platforms = ["x86_64-linux"];
  };
})
