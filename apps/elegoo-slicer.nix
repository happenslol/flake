{
  lib,
  appimageTools,
  fetchurl,
  cacert,
  glib-networking,
}: let
  pname = "elegoo-slicer";
  version = "1.5.3.5";

  src = fetchurl {
    url = "https://github.com/ELEGOO-3D/ElegooSlicer/releases/download/v${version}/ElegooSlicer_Linux_V${version}.AppImage";
    hash = "sha256-ezs/CODQ1Ru0cshYZdG+mwwoOFQj2rocsMOyJdAQGvw=";
  };

  appimageContents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    # The AppImage bundles only zlib, lzma, expat and libmspack (plus the
    # Agora SDK); everything else comes from the FHS env. WebKitGTK and
    # libsoup aren't in appimageTools' default package set.
    extraPkgs = pkgs:
      with pkgs; [
        libsoup_3
        webkitgtk_4_1
        glib-networking
      ];

    profile = ''
      # The app probes distro-specific CA bundle paths that don't exist on
      # NixOS; point it at nixpkgs' bundle so TLS works out of the box.
      export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
      # libsoup/WebKit get their TLS backend from glib-networking's GIO
      # module (libgiognutls.so); without this GIO reports "TLS support is
      # not available" and logins fail.
      export GIO_EXTRA_MODULES="${glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"
    '';

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/com.orcaslicer.ElegooSlicer.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/com.orcaslicer.ElegooSlicer.desktop \
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
