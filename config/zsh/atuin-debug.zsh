autoload -U add-zsh-hook

export ATUIN_SESSION=$(atuin uuid)
export ATUIN_HISTORY="atuin history list"

function log() {
    echo "$@" >> /tmp/atuin.log
}

_atuin_preexec() {
    log "Running pre-exec for $1\n"
    local id
    id=$(/run/current-system/sw/bin/time -a -o /tmp/atuin.log atuin history start -- "$1")
    export ATUIN_HISTORY_ID="$id"
    log "Pre-exec done for $1\n"
}

_atuin_precmd() {
    local EXIT="$?"

    [[ -z "${ATUIN_HISTORY_ID}" ]] && return

    log "Running pre-cmd for $1"
    (RUST_LOG=error /run/current-system/sw/bin/time -a -o /tmp/atuin.log atuin history end --exit $EXIT -- $ATUIN_HISTORY_ID &) >/dev/null 2>&1
    log "Pre-cmd done for $1"
}

_atuin_search() {
    log "Searching\n"
    emulate -L zsh
    zle -I

    # Switch to cursor mode, then back to application
    echoti rmkx
    # swap stderr and stdout, so that the tui stuff works
    # TODO: not this
    # shellcheck disable=SC2048
    output=$(RUST_LOG=error /run/current-system/sw/bin/time -a -o /tmp/atuin.log atuin search $* -i -- $BUFFER 3>&1 1>&2 2>&3)
    echoti smkx

    if [[ -n $output ]]; then
        RBUFFER=""
        LBUFFER=$output
    fi

    zle reset-prompt
    log "\n"
}

_atuin_up_search() {
    _atuin_search --shell-up-key-binding
}

add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd _atuin_precmd

zle -N _atuin_search_widget _atuin_search
zle -N _atuin_up_search_widget _atuin_up_search

bindkey '^r' _atuin_search_widget
