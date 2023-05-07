if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

bindkey -M emacs '^[[1;5C' forward-word
bindkey -M viins '^[[1;5C' forward-word
bindkey -M vicmd '^[[1;5C' forward-word

bindkey -M emacs '^[[1;5D' backward-word
bindkey -M viins '^[[1;5D' backward-word
bindkey -M vicmd '^[[1;5D' backward-word

bindkey -M menuselect '^[[Z' reverse-menu-complete

autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search

bindkey -M emacs "${terminfo[kcuu1]}" up-line-or-beginning-search
bindkey -M viins "${terminfo[kcuu1]}" up-line-or-beginning-search
bindkey -M vicmd "${terminfo[kcuu1]}" up-line-or-beginning-search

autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M emacs "${terminfo[kcud1]}" down-line-or-beginning-search
bindkey -M viins "${terminfo[kcud1]}" down-line-or-beginning-search
bindkey -M vicmd "${terminfo[kcud1]}" down-line-or-beginning-search

function _keymap_nvim() { nvim-nightly; zle redisplay }
zle -N keymap-nvim-widget _keymap_nvim
bindkey "^N" keymap-nvim-widget

function _keymap_lazygit() { lazygit; zle redisplay }
zle -N keymap-lazygit-widget _keymap_lazygit
bindkey "^G" keymap-lazygit-widget

function _keymap_ls() {
  echo
  exa -la --git --icons --group-directories-first
  zle redisplay
}
zle -N keymap-ls-widget _keymap_ls
bindkey "^K" keymap-ls-widget

zle -N keymap-atuin-widget _atuin_search
bindkey "^R" keymap-atuin-widget
