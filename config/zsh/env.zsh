[[ -f ~/.secrets ]] && source ~/.secrets

export PATH="$PATH:$HOME/.local/bin"
export LANG=en_US.UTF-8
export EDITOR="nvim"

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Go
export GOPRIVATE=*.g51.dev,g51.dev
export GOPATH="/home/happens/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$HOME/go/bin"

# Rust
export PATH="$PATH:$HOME/.cargo/bin"
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

# fzf
export FZF_DEFAULT_COMMAND="rg --files --hidden"

# direnv config
export DIRENV_LOG_FORMAT=""

# pager config
export PAGER="less -+X"
export BAT_PAGER="less -+X"
export DELTA_PAGER="less -+X"

# Node/npm
export PATH="$PATH:$HOME/.npm-packages/bin"
export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-"$HOME/.npm-packages"}"
export NODE_PATH="${NODE_PATH:-"$HOME/.npm-packages/lib/node_modules"}"
export NODE_OPTIONS="--max-old-space-size=16384"

# git scripts
export PATH="$PATH:$HOME/.git-scripts"
