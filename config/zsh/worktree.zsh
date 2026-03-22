# Worktree helper — creates git worktrees with automatic setup.
#
# Usage:
#   wt <branch> [base]     cd into worktree (creates if needed)
#   worktree <branch> [base]   prints worktree path to stdout
#
# Environment variables (set per-repo in devshell shellHook):
#   WORKTREE_EXTRA_FILES  Colon-separated relative paths to copy from the
#                         main worktree (e.g. "apps/backend/.env:.npmrc").
#   WORKTREE_POST_HOOK    Path to an executable that receives $worktree_path
#                         and $main_dir as arguments.
#
# Zsh hook (set per-repo in devshell shellHook):
#   Define a `worktree_post_hook` function to run after `wt` creates a
#   worktree. It receives the worktree path and main repo dir as arguments.
#
#   Example in a devshell shellHook:
#     worktree_post_hook() {
#       local wt_path="$1" main_dir="$2"
#       cp "$main_dir/some/config" "$wt_path/some/config"
#     }

function worktree() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: worktree <branch> [base]" >&2
    return 1
  fi

  local branch="$1"
  local base="${2:-main}"

  local main_dir
  main_dir=$(git rev-parse --path-format=absolute --git-common-dir)
  main_dir=$(realpath "${main_dir%/.git}")
  local repo_name=$(basename "$main_dir")
  local worktree_path="$main_dir/../${repo_name}-worktrees/${branch//\//_}"
  worktree_path=$(realpath -m "$worktree_path")

  if [[ -d "$worktree_path" ]]; then
    echo "$worktree_path"
    return 0
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$main_dir" worktree add "$worktree_path" "$branch" >&2
  elif git -C "$main_dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git -C "$main_dir" worktree add --track -b "$branch" "$worktree_path" "origin/$branch" >&2
  else
    git -C "$main_dir" worktree add -b "$branch" "$worktree_path" "$base" >&2
  fi

  # copy git exclude
  local wt_git_dir=$(git -C "$worktree_path" rev-parse --git-dir)
  local main_git_dir=$(git -C "$main_dir" rev-parse --git-common-dir)
  if [[ -f "$main_git_dir/info/exclude" ]]; then
    mkdir -p "$wt_git_dir/info"
    cp "$main_git_dir/info/exclude" "$wt_git_dir/info/exclude"
  fi

  # copy claude settings
  if [[ -f "$main_dir/.claude/settings.local.json" ]]; then
    mkdir -p "$worktree_path/.claude"
    cp "$main_dir/.claude/settings.local.json" "$worktree_path/.claude/settings.local.json"
  fi

  # copy envrc files and allow direnv
  if [[ -f "$main_dir/.envrc" ]]; then
    cp "$main_dir/.envrc" "$worktree_path/.envrc"
    direnv allow "$worktree_path" >&2
  fi
  if [[ -f "$main_dir/.envrc.local" ]]; then
    cp "$main_dir/.envrc.local" "$worktree_path/.envrc.local"
  fi

  # copy extra files (colon-separated WORKTREE_EXTRA_FILES)
  if [[ -n "${WORKTREE_EXTRA_FILES:-}" ]]; then
    local -a _wt_files
    _wt_files=("${(@s/:/)WORKTREE_EXTRA_FILES}")
    local _wt_f
    for _wt_f in "${_wt_files[@]}"; do
      if [[ -f "$main_dir/$_wt_f" ]]; then
        mkdir -p "$(dirname "$worktree_path/$_wt_f")"
        cp "$main_dir/$_wt_f" "$worktree_path/$_wt_f"
      fi
    done
  fi

  # install dependencies based on lockfile
  if [[ -f "$worktree_path/pnpm-lock.yaml" ]]; then
    pnpm --dir "$worktree_path" install >&2
  elif [[ -f "$worktree_path/bun.lockb" ]] || [[ -f "$worktree_path/bun.lock" ]]; then
    (cd "$worktree_path" && bun install) >&2
  fi

  # run post-creation hook if defined
  if [[ -n "${WORKTREE_POST_HOOK:-}" ]]; then
    "$WORKTREE_POST_HOOK" "$worktree_path" "$main_dir" >&2
  fi

  echo "$worktree_path"
}

function wt() {
  local dir
  dir="$(worktree "$@")" || return $?
  if typeset -f worktree_post_hook > /dev/null; then
    local main_dir
    main_dir="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)"
    worktree_post_hook "$dir" "${main_dir%/.git}"
  fi
  cd "$dir"
}

_worktree() {
  local -a branches
  branches=(${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | grep -v '^HEAD' | sort -u)"})
  case $CURRENT in
    2) _describe 'branch' branches ;;
    3) _describe 'base branch' branches ;;
  esac
}
compdef _worktree worktree
compdef _worktree wt
