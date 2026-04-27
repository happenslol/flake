{
  symlinkJoin,
  runCommand,
  fetchurl,
  writeShellScriptBin,
  makeDesktopItem,
  google-chrome,
}: let
  url = "https://web.whatsapp.com/";
  wmClass = "WhatsApp";

  bin = writeShellScriptBin "whatsapp" ''
    exec ${google-chrome}/bin/google-chrome-stable \
      --app=${url} \
      --class=${wmClass} \
      --name=${wmClass} \
      --user-data-dir="''${XDG_DATA_HOME:-$HOME/.local/share}/whatsapp-app" \
      "$@"
  '';

  desktopItem = makeDesktopItem {
    name = "whatsapp";
    desktopName = "WhatsApp";
    genericName = "Messenger";
    comment = "WhatsApp Web in app mode";
    icon = "whatsapp";
    exec = "whatsapp";
    categories = ["Network" "InstantMessaging"];
    startupWMClass = wmClass;
  };

  iconSrc = fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg";
    hash = "sha256-3WpNssOUyhGqirCHNp8vUKEub4dOSdt7HVYJ0Kj7KMo=";
  };

  icon = runCommand "whatsapp-icon" {} ''
    install -Dm644 ${iconSrc} $out/share/icons/hicolor/scalable/apps/whatsapp.svg
  '';
in
  symlinkJoin {
    name = "whatsapp";
    paths = [bin desktopItem icon];
    meta = {
      description = "WhatsApp Web wrapped as a standalone app via Chrome --app mode";
      homepage = "https://web.whatsapp.com/";
      mainProgram = "whatsapp";
    };
  }
