{ inputs, ... }:

{
  imports = [ inputs.grub2-themes.nixosModule ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
  };

  boot.loader.grub2-theme = {
    enable = true;
    theme = "stylish";
    splashImage = null;
    footer = false;
    screen = "2k";
  };
}
