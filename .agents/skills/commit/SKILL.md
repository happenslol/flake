---
name: commit
description: Commit staged and unstaged changes with short, lowercase commit messages following this repo's conventions. Use when the user asks to commit.
disable-model-invocation: true
---

Commit all current changes in the working tree. Group changes into multiple commits if they belong to different logical areas — never mix unrelated changes in one commit.

> **Note:** In this repo, running `nixos-rebuild switch` or `home-manager switch` stages all tracked files automatically so the flake sees them. This means changes are often already staged when this skill is invoked. Treat staged and unstaged changes the same — they all need to be committed.

## Process

1. Run `git status` and `git diff --staged` (plus `git diff` for any unstaged changes) to understand all changes.
2. Identify logical groups of changes. Each group should get its own commit. Changes that would need a different prefix MUST be in separate commits.
3. For each group, stage only the relevant files (they may already be staged), then commit.
4. After all commits, run `git status` to confirm a clean tree.

## Commit message rules

- All lowercase, short (under ~60 chars)
- No period at the end
- No `Co-Authored-By` trailer
- Description (body) is optional — only include it if there's meaningful reasoning, a link to a related issue, or a tutorial reference. Most commits should have no body.

## Prefix rules

Use a prefix when the change is scoped to a specific program or host:

- **Program-scoped:** `neovim: update plugins`, `zsh: add alias`, `nix: update flake inputs`, `kitty: change font size`, `sway: update keybinds`
- **Host-scoped:** `roe2: update media services`, `mira: adjust power settings`
- **Host + program:** `mira/niri: update touchpad settings`, `roe2/sway: change output config`
- **No prefix** for broad cross-cutting changes: `update packages`, `add new devshell`

The prefix is the program name as a user would refer to it (e.g. `neovim` not `nvim`, `kitty` not `kitty.conf`), or the host name from `hosts/`.

## Grouping rules

- Changes to `config/nvim/` and `config/sway/` = two commits (different programs)
- Changes to `hosts/mira/configuration.nix` and `hosts/roe2/configuration.nix` for different reasons = two commits
- Changes to `packages.nix` and `overlay.nix` for the same new package = one commit
- Changes to `system.nix` and `home.nix` for the same feature = one commit

## Committing

- Stage specific files with `git add <paths>`, never `git add -A` or `git add .` when making multiple commits
- Use a HEREDOC for the commit message:
  ```
  git commit -m "$(cat <<'EOF'
  prefix: short message
  EOF
  )"
  ```
- If a body is needed:
  ```
  git commit -m "$(cat <<'EOF'
  prefix: short message

  longer explanation of why this change was made
  EOF
  )"
  ```
