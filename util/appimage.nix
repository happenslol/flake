{
  lib,
  fetchurl,
  appimage-run,
  makeDesktopItem,
  writeShellScriptBin,
  symlinkJoin,
}: {
  name,
  url,
  sha256,
  icon ? null,
  iconSha256 ? null,
  desktopName ? name,
  comment ? "",
  categories ? ["Utility"],
  mimeTypes ? [],
  extraArgs ? [],
}: let
  appimage = fetchurl {inherit url sha256;};

  fetchedIcon =
    if icon != null && iconSha256 != null
    then
      fetchurl {
        url = icon;
        sha256 = iconSha256;
      }
    else icon;

  script = writeShellScriptBin name ''
    exec ${appimage-run}/bin/appimage-run ${appimage} ${lib.escapeShellArgs extraArgs} "$@"
  '';

  desktop = makeDesktopItem {
    inherit name desktopName comment categories mimeTypes;
    exec = "${script}/bin/${name} %u";
    icon =
      if fetchedIcon != null
      then fetchedIcon
      else name;
  };
in
  symlinkJoin {
    name = "${name}-with-desktop";
    paths = [script desktop];
  }
