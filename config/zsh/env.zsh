[[ -f ~/.secrets ]] && source ~/.secrets

export PATH="$PATH:$HOME/.local/bin"
export LANG=en_US.UTF-8
export EDITOR="nvim"

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Scripts
export PATH="$PATH:$HOME/.flake/scripts"

# Go
export GOPRIVATE=*.g51.dev,g51.dev
export GOPATH="/home/happens/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$HOME/go/bin"

# Rust
export PATH="$PATH:$HOME/.cargo/bin"

# fzf
export FZF_DEFAULT_COMMAND="rg --files --hidden"
