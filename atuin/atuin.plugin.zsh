# shellcheck disable=SC2034,SC2153,SC2154,SC2086,SC2155,SC2299

# Above line is because shellcheck doesn't support zsh, per
# https://github.com/koalaman/shellcheck/wiki/SC1071, and the ignore: param in
# ludeeus/action-shellcheck only supports _directories_, not _files_. So
# instead, we manually add any error the shellcheck step finds in the file to
# the above line ...

# Source this in your ~/.zshrc
autoload -U add-zsh-hook

zmodload zsh/datetime 2>/dev/null

# If zsh-autosuggestions is installed, configure it to use Atuin's search. If
# you'd like to override this, then add your config after the $(atuin init zsh)
# in your .zshrc

# from https://www.aloxaf.com/2024/02/manage_zsh_shell_with_atuin/
_sql_escape() {
    print -r -- ${${@//\'/\'\'}//$'\x00'}
}

_zsh_autosuggest_strategy_atuin() {
    emulate -L zsh

    local reply=$(sqlite3 "${HOME}/.local/share/atuin/history.db" "
        SELECT command
        FROM (
            SELECT h1.command
            FROM history h1, history h2
            WHERE h1.ROWID = h2.ROWID + 1
                AND h1.session = h2.session
                AND h2.exit = 0
                AND h1.command LIKE '$(_sql_escape "$1%")'
                AND h2.command = '$(_sql_escape "${history[$((HISTCMD-1))]}")' 
                AND h1.cwd = '$(_sql_escape "$PWD")'
            ORDER BY h1.timestamp DESC
            LIMIT 1
        )
        UNION ALL
        SELECT command
        FROM (
            SELECT command
            FROM history
            WHERE cwd = '$(_sql_escape "$PWD")' AND command LIKE '$(_sql_escape "$1%")'
            ORDER BY timestamp DESC
            LIMIT 1
        )
        UNION ALL
        SELECT command
        FROM (
            SELECT command
            FROM history
            WHERE command LIKE '$(_sql_escape "$1%")'
            ORDER BY timestamp DESC
            LIMIT 1
        )
        LIMIT 1
    ")

    if [[ -f "${HOME}/.local/share/atuin/history.db" ]] && (( ${+commands[sqlite3]} )); then
        typeset -g suggestion=$reply
    else
        suggestion=$(ATUIN_QUERY="$1" atuin search --cmd-only --limit 1 --search-mode prefix)
    fi

}

if [ -n "${ZSH_AUTOSUGGEST_STRATEGY:-}" ]; then
    ZSH_AUTOSUGGEST_STRATEGY=("atuin" "${ZSH_AUTOSUGGEST_STRATEGY[@]}")
else
    ZSH_AUTOSUGGEST_STRATEGY=("atuin")
fi

export ATUIN_SESSION=$(atuin uuid)
ATUIN_HISTORY_ID=""

_atuin_preexec() {
    local id
    id=$(atuin history start -- "$1")
    export ATUIN_HISTORY_ID="$id"
    __atuin_preexec_time=${EPOCHREALTIME-}
}

_atuin_precmd() {
    local EXIT="$?" __atuin_precmd_time=${EPOCHREALTIME-}

    [[ -z "${ATUIN_HISTORY_ID:-}" ]] && return

    local duration=""
    if [[ -n $__atuin_preexec_time && -n $__atuin_precmd_time ]]; then
        printf -v duration %.0f $(((__atuin_precmd_time - __atuin_preexec_time) * 1000000000))
    fi

    (ATUIN_LOG=error atuin history end --exit $EXIT ${duration:+--duration=$duration} -- $ATUIN_HISTORY_ID &) >/dev/null 2>&1
    export ATUIN_HISTORY_ID=""
}

_atuin_search() {
    emulate -L zsh
    zle -I

    # swap stderr and stdout, so that the tui stuff works
    # TODO: not this
    local output
    # shellcheck disable=SC2048
    output=$(ATUIN_SHELL_ZSH=t ATUIN_LOG=error ATUIN_QUERY=$BUFFER atuin search $* -i 3>&1 1>&2 2>&3)

    zle reset-prompt

    if [[ -n $output ]]; then
        RBUFFER=""
        LBUFFER=$output

        if [[ $LBUFFER == __atuin_accept__:* ]]
        then
            LBUFFER=${LBUFFER#__atuin_accept__:}
            zle accept-line
        fi
    fi
}
_atuin_search_vicmd() {
    _atuin_search --keymap-mode=vim-normal
}
_atuin_search_viins() {
    _atuin_search --keymap-mode=vim-insert
}

add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd _atuin_precmd

zle -N atuin-search _atuin_search
zle -N atuin-search-vicmd _atuin_search_vicmd
zle -N atuin-search-viins _atuin_search_viins

# These are compatibility widget names for "atuin <= 17.2.1" users.
zle -N _atuin_search_widget _atuin_search
zle -N _atuin_up_search_widget _atuin_up_search

bindkey -M emacs '^r' atuin-search
bindkey -M viins '^r' atuin-search-viins
bindkey -M vicmd '/' atuin-search
