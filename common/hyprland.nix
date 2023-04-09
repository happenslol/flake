{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.hyprland.nixosModules.default];

  programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [swww];
}
