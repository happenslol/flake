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

      main_dir=$(git rev-parse --path-format=absolute --git-common-dir)
      main_dir="''${main_dir%/.git}"
      worktree_path="$main_dir/../sigma-worktrees/''${branch//\//_}"

      if [ -d "$worktree_path" ]; then
        echo "$worktree_path"
        exit 0
      fi

      if git show-ref --verify --quiet "refs/heads/$branch"; then
        git -C "$main_dir" worktree add "$worktree_path" "$branch" >&2
      elif git -C "$main_dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        git -C "$main_dir" worktree add --track -b "$branch" "$worktree_path" "origin/$branch" >&2
      else
        git -C "$main_dir" worktree add -b "$branch" "$worktree_path" "$base" >&2
      fi

      cp "$main_dir/apps/backend/.env" "$worktree_path/apps/backend/.env"
      cp "$main_dir/tasks/automator/.env" "$worktree_path/tasks/automator/.env"
      cp "$main_dir/.envrc" "$worktree_path/.envrc"
      if [ -f "$main_dir/.claude/settings.local.json" ]; then
        mkdir -p "$worktree_path/.claude"
        cp "$main_dir/.claude/settings.local.json" "$worktree_path/.claude/settings.local.json"
      fi

      wt_git_dir=$(git -C "$worktree_path" rev-parse --git-dir)
      main_git_dir=$(git -C "$main_dir" rev-parse --git-common-dir)
      if [ -f "$main_git_dir/info/exclude" ]; then
        mkdir -p "$wt_git_dir/info"
        cp "$main_git_dir/info/exclude" "$wt_git_dir/info/exclude"
      fi

      pnpm --dir "$worktree_path" install >&2

      direnv allow "$worktree_path" >&2

      echo "$worktree_path"
    '';

    worktreeCompletion = pkgs.writeText "worktree-completion-zsh" ''
      _worktree() {
        local -a branches
        branches=(''${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | grep -v '^HEAD' | sort -u)"})
        case $CURRENT in
          2) _describe 'branch' branches ;;
          3) _describe 'base branch' branches ;;
        esac
      }
      compdef _worktree worktree
      compdef _worktree wt
    '';
  in pkgs.mkShell {
    name = "sigma";
    packages = with pkgs; [fnm playwright watchman worktree];
    shellHook = ''
      export ZSH_DEVSHELL_COMPLETIONS="${worktreeCompletion}''${ZSH_DEVSHELL_COMPLETIONS:+:$ZSH_DEVSHELL_COMPLETIONS}"
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
