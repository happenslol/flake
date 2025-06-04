bindkey -e

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

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word

bindkey -M menuselect '^[[Z' reverse-menu-complete

autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search

bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search

autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

function _keymap_nvim() { nvim; zle reset-prompt }
zle -N keymap-nvim-widget _keymap_nvim
bindkey "^N" keymap-nvim-widget

function _keymap_nvim_blank() { NVIM_SESSION_BLANK=1 nvim-nightly; zle reset-prompt }
zle -N keymap-nvim-blank-widget _keymap_nvim_blank
bindkey "^[[109;5u" keymap-nvim-blank-widget

function _keymap_lazygit() { lazygit; zle reset-prompt }
zle -N keymap-lazygit-widget _keymap_lazygit
bindkey "^G" keymap-lazygit-widget

function _keymap_yazi() { yazi; zle reset-prompt }
zle -N keymap-yazi-widget _keymap_yazi
bindkey "^F" keymap-yazi-widget

function _keymap_ls() {
  echo
  eza -la --git --icons --group-directories-first
  echo "\n"
  zle reset-prompt
}
zle -N keymap-ls-widget _keymap_ls
bindkey "^K" keymap-ls-widget
