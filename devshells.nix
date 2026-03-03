# Use with: # `use flake ~/.flake#<name>`
pkgs: {
  sigma = let
    worktree = pkgs.writeShellScriptBin "worktree" ''
      set -euo pipefail

      if [ $# -lt 1 ]; then
        echo "Usage: worktree <branch> [base]" >&2
        exit 1
      fi

      branch="$1"
      base="''${2:-main}"
      worktree_path=".worktrees/$branch"

      if git show-ref --verify --quiet "refs/heads/$branch"; then
        git worktree add "$worktree_path" "$branch" >&2
      else
        git worktree add -b "$branch" "$worktree_path" "$base" >&2
      fi

      cp apps/backend/.env "$worktree_path/apps/backend/.env"
      cp apps/automator/.env "$worktree_path/apps/automator/.env"
      cp .envrc "$worktree_path/.envrc"

      pnpm --dir "$worktree_path" install >&2

      direnv allow "$worktree_path" >&2

      echo "$worktree_path"
    '';
  in pkgs.mkShell {
    name = "sigma";
    packages = with pkgs; [fnm playwright watchman worktree];
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
