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
}
