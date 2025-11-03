# Use with: # `use flake ~/.flake#<name>`
pkgs: {
  sigma = pkgs.mkShell {
    name = "sigma";
    packages = with pkgs; [fnm playwright watchman];
    shellHook = ''
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
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
