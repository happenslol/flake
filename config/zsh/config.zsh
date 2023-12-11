# Configure history
export HISTFILE=~/.zsh_history
export HISTSIZE=1000
export SAVEHIST=500

setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt share_history

unsetopt flowcontrol
unsetopt menu_complete
setopt auto_menu
setopt complete_in_word
setopt always_to_end

setopt auto_cd
setopt multios
setopt prompt_subst

# Make sure default ls colors are set
if [[ -z "$LS_COLORS" ]]; then
  (( $+commands[dircolors] )) && eval "$(dircolors -b)"
fi

# Configure completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZSH_CACHE_DIR
zstyle ':completion:*:*:*:*:*' menu select

zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Load required modules
zmodload zsh/complist

# Configure autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=('atuin')
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='20'
ZSH_AUTOSUGGEST_USE_ASYNC='true'
ZSH_AUTOSUGGEST_MANUAL_REBIND='true'

# Clear autosuggestions when using atuin
# NOTE: Widgets starting with '_' don't work here, which
# is why we have to rebind the atuin widget.
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=('keymap-atuin-widget')

# Use atuin history for autosuggestions
function _zsh_autosuggest_strategy_atuin() {
  # FIXME: This currently escapes incorrectly, since atuin is hard-coded
  # to replace '*' with '%', and we're not escaping any SQL LIKE wildcards.
  typeset -g suggestion="$(atuin search --search-mode prefix --cmd-only --limit 1 "$1")"
}
