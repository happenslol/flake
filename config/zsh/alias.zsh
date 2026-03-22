alias k="kubectl "
alias sr="steam-run "
alias tf="terraform "

alias pnpm='node $(realpath $(unalias pnpm; which pnpm)) '
alias turbo='node $(realpath $(unalias pnpm; which pnpm)) turbo --ui stream --concurrency 8 --no-update-notifier '

alias reload="source ~/.zshrc"
alias svim="sudo -E nvim"

# Nix shells with zsh as default
alias nsh="nix-shell --command zsh "
alias ndv="nix develop --command zsh "

# Remap ls commands and shortcuts to eza
alias l="eza -la --git --icons --group-directories-first "
alias lt="eza --tree --icons --group-directories-first "

# Force color in watch commands
alias watch="watch --color "

# Jump directories more quickly
alias -g ...="cd ../.."
alias -g ....="cd ../../.."
alias -g .....="cd ../../../.."
alias -g ......="cd ../../../../.."

function ccd() { mkdir -p "$@" && cd "$@" }
alias rd="rmdir "

# Git shortcuts
alias gs="git status "
alias ga="git add "
alias gt="git tag "
alias gaa="git add ."
alias gau="git add -u "
alias gss="git switch "
alias grs="git restore "
alias gr="git reset "
alias grr="git reset --hard "
alias gc="git commit "
alias gcf="git commit --no-verify "
alias gp="git pull "
alias gpp="git push "
alias gscm="git cm "
alias gsh="git show "
alias gd="git diff "
alias gm="git merge "

# Custom commands
alias flake="just -f ~/.flake/justfile "
alias nixdev="nix develop --command zsh "

# Devices
alias bt="bluetuith "
alias sink="pactl set-default-sink "
alias src="pactl set-default-source "
alias unmute="pactl set-sink-mute @DEFAULT_SINK@ false"
alias mute="pactl set-sink-mute @DEFAULT_SINK@ true"

# Claude Code profiles
alias claude-oc="CLAUDE_CONFIG_DIR=~/.claude-oc claude "
