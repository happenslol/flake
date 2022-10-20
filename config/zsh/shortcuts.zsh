# Frequently used
alias k="kubectl "
alias n="nvim "

alias reload="source ~/.zshrc"
alias svim="sudo -E nvim"

# Remap utils to modern versions
alias cat="bat "
alias grep="rg "
alias mosh="ssh "

# Remap ls commands and shortcuts to exa
alias l="exa -la --git --icons --group-directories-first "
alias ls="exa --icons --group-directories-first "
alias lt="exa --tree --icons --group-directories-first "

# Force color in watch commands
alias watch="watch --color "

# Jump directories more quickly
alias -g ...="cd ../.."
alias -g ....="cd ../../.."
alias -g .....="cd ../../../.."
alias -g ......="cd ../../../../.."

alias md="mkdir -p "
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
