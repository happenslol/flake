[[ -z "$ZPROF" ]] || zmodload zsh/zprof

export TERM=wezterm

if [[ -n "${commands[fzf-share]}" ]]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

source ~/.config/zsh/ssh.zsh
source ~/.config/zsh/config.zsh
source ~/.config/zsh/keymaps.zsh
source ~/.config/zsh/env.zsh
source ~/.config/zsh/alias.zsh

eval "$(starship init zsh)"
eval "$(zoxide init --cmd j zsh)"
eval "$(direnv hook zsh)"

eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)"
# source ~/.config/zsh/atuin-debug.zsh

autoload -Uz compinit
for _ in ~/.zcompdump(N.mh+24); do compinit; done
compinit -C

if [[ -z "$SSH_AUTH_SOCK" ]]; then
  eval "$(ssh-agent -s)" &> /dev/null

  PERSONAL_KEY="~/.ssh/$(hostname).personal.id_ed25519"
  [[ -f "$PERSONAL_KEY" ]] && ssh-add "$PERSONAL_KEY" &> /dev/null
fi

[[ -z "$ZPROF" ]] || zprof
