{
  lib,
  appimageTools,
  fetchurl,
  bzip2,
  cacert,
  glib-networking,
}: let
  pname = "elegoo-slicer";
  version = "1.5.1.6";

  src = fetchurl {
    url = "https://github.com/ELEGOO-3D/ElegooSlicer/releases/download/v${version}/ElegooSlicer_Linux_V${version}.AppImage";
    hash = "sha256-fL44zEAQWaf1QOq8A5+pVseze9uhinJNRKkI94ZG9g4=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    # The AppImage links against libraries it does not bundle. Normal-SONAME
    # libs are resolved via the FHS ld cache; bzip2 is special: the binary
    # wants `libbz2.so.1.0`, but nixpkgs' libbz2 has SONAME `libbz2.so.1`, so
    # ldconfig never records the `.1.0` name. Putting bzip2 on LD_LIBRARY_PATH
    # lets the loader find it by filename instead (AppRun preserves the var).
    extraPkgs = pkgs:
      with pkgs; [
        bzip2
        zstd
        libsoup_3
        webkitgtk_4_1
        libmspack
        glib-networking
      ];

    profile = ''
      export LD_LIBRARY_PATH="${lib.makeLibraryPath [bzip2]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # The app probes distro-specific CA bundle paths that don't exist on
      # NixOS; point it at nixpkgs' bundle so TLS works out of the box.
      export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
      # libsoup/WebKit get their TLS backend from glib-networking's GIO
      # module (libgiognutls.so); without this GIO reports "TLS support is
      # not available" and logins fail.
      export GIO_EXTRA_MODULES="${glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"
    '';

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/ElegooSlicer.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/ElegooSlicer.desktop \
        --replace-fail "Exec=AppRun" "Exec=${pname}"
      install -Dm444 ${appimageContents}/usr/share/icons/hicolor/192x192/apps/ElegooSlicer.png \
        $out/share/icons/hicolor/192x192/apps/ElegooSlicer.png
    '';

    meta = {
      description = "PC software for ELEGOO 3D printers, based on OrcaSlicer";
      homepage = "https://github.com/ELEGOO-3D/ElegooSlicer";
      license = lib.licenses.agpl3Only;
      mainProgram = "elegoo-slicer";
      platforms = ["x86_64-linux"];
    };
  }
