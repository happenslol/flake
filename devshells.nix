# Use with: # `use flake ~/.flake#<name>`
{
  pkgs,
  pkgs-playwright,
}: {
  sigma = pkgs.mkShell {
    name = "sigma";
    packages = with pkgs; [fnm pkgs-playwright.playwright];
    shellHook = ''
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      export PLAYWRIGHT_BROWSERS_PATH="${pkgs-playwright.playwright-driver.browsers}"
      eval "$(fnm env --use-on-cd --resolve-engines --log-level quiet)"
    '';
  };

  gui = pkgs.mkShell rec {
    name = "gui";
    packages = with pkgs; [
      libxkbcommon
      vulkan-loader
      wayland
    ];

    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath packages;
  };
}
