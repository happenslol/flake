pkgs: {
  sigma = pkgs.mkShell {
    name = "sigma";
    packages = with pkgs; [fnm];
    shellHook = ''
      export PLAYWRIGHT_BROWSERS_PATH="''$HOME/.local/share/sigma/playwright-browsers"
      eval "$(fnm env --use-on-cd --resolve-engines --log-level quiet)"
    '';
  };
}
