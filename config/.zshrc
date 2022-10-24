[ -z "$ZPROF" ] || zmodload zsh/zprof

source ~/.config/zsh/keymap.zsh
source ~/.config/zsh/env.zsh
source ~/.config/zsh/config.zsh
source ~/.config/zsh/shortcuts.zsh

eval "$(starship init zsh)"
eval "$(zoxide init --cmd j zsh)"

if [ -n "${commands[fzf-share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

autoload -Uz compinit
for _ in ~/.zcompdump(N.mh+24); do compinit; done
compinit -C

[ -z "$ZPROF" ] || zprof
