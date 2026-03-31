[[ -z "$ZPROF" ]] || zmodload zsh/zprof

if [[ -n "${commands[fzf-share]}" ]]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

source ~/.config/zsh/ssh.zsh
source ~/.config/zsh/config.zsh

autoload -Uz compinit
for _ in ~/.zcompdump(N.mh+24); do compinit; done
compinit -C

source ~/.config/zsh/keymaps.zsh
source ~/.config/zsh/env.zsh
source ~/.config/zsh/alias.zsh
source ~/.config/zsh/worktree.zsh
source ~/.config/zsh/util.zsh

eval "$(starship init zsh)"
eval "$(zoxide init --cmd j zsh)"
eval "$(direnv hook zsh)"
eval "$(atuin init zsh --disable-ai --disable-up-arrow)"

# Source devshell completions set via direnv (avoid compinit rescan)
_load_devshell_completions() {
  if [[ -n "$ZSH_DEVSHELL_COMPLETIONS" && "$ZSH_DEVSHELL_COMPLETIONS" != "$_loaded_devshell_completions" ]]; then
    _loaded_devshell_completions="$ZSH_DEVSHELL_COMPLETIONS"
    local file
    for file in ${(s.:.)ZSH_DEVSHELL_COMPLETIONS}; do
      [[ -f "$file" ]] && source "$file"
    done
  fi
}
precmd_functions+=(_load_devshell_completions)

if [[ -z "$SSH_AUTH_SOCK" ]]; then
  eval "$(ssh-agent -s)" &> /dev/null

  PERSONAL_KEY="~/.ssh/$(hostname).personal.id_ed25519"
  [[ -f "$PERSONAL_KEY" ]] && ssh-add "$PERSONAL_KEY" &> /dev/null
fi

[[ -z "$ZPROF" ]] || zprof
