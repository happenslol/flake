# 1password has a lot of problems when running under wayland (broken copy/paste
# being the most egregious). Until that issue is resolved, we'll have to deal
# with a blurry GUI.
self: super: {
  _1password-gui = super._1password-gui.overrideAttrs (_: {
    postFixup = ''
      wrapProgram $out/bin/1password --set ELECTRON_OZONE_PLATFORM_HINT x11
    '';
  });
}
