#!/usr/bin/env zsh

# Based on https://github.com/romkatv/zsh-bench/blob/master/configs/diy++/skel/.zshrc

##### .zshrc

PS1="Ready > "
RPS1="%F{240}Loading...%f"

############
### Environment
############

ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
ZSHDDIR="${ZDOTDIR}/conf.d"
ZDATADIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
ZPLUGINDIR="${ZDATADIR}/plugins"
ZCACHEDIR="${ZDATADIR}/cache"
[ -d "${ZCACHEDIR}" ] || mkdir -p "${ZCACHEDIR}"

[[ ":$PATH:" == *":$HOME/bin:"* ]] || export PATH="${HOME}/bin:$PATH"

if [[ $(tty) == /dev/tty* ]] ; then
  export LANG=C.UTF-8
elif [[ $(tty) == /dev/pts/* ]] ; then
  export LANG=zh_CN.UTF-8
fi

if (( ${+commands[gpg]} )); then
  export GPG_TTY=$(tty)
fi

if [[ -z "${EDITOR}" ]]; then
  for _editor in helix hx nvim vim nano; do
    if command -v "${_editor}" &> /dev/null; then
      export EDITOR="${_editor}"
      # export VISUAL="${EDITOR}"
      break
    fi
  done
fi

if (( ${+commands[fd]} )); then
  export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude '.git' --exclude 'node_modules'"
elif (( ${+commands[fdfind]} )); then
  export FZF_DEFAULT_COMMAND="fdfind --hidden --follow --exclude '.git' --exclude 'node_modules'"
elif (( ${+commands[rg]} )); then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,node_modules}/**"'
else
  export FZF_DEFAULT_COMMAND='find . -type f -not \( -path "*/.git/*" -o -path "./node_modules/*" \)'
fi

#
### End of Environment
#

############
### Features
############

# Basic
setopt always_to_end
setopt extended_glob
setopt no_beep
setopt no_flow_control
setopt no_nomatch
setopt prompt_subst

# Directory
setopt auto_cd
DIRSTACKSIZE=16
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_minus

# Job Control
setopt long_list_jobs
setopt no_bg_nice
setopt no_check_jobs
setopt no_hup

# I/O
setopt interactive_comments
setopt no_clobber

# History
HISTFILE="${ZCACHEDIR}/.zsh_history"
HISTSIZE='261120'
SAVEHIST='261120'
# setopt append_history
# setopt extended_history
setopt inc_append_history
# setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_space
# setopt hist_find_no_dups
setopt hist_verify
setopt share_history

#
### End of Features
#

############
### Aliases
############

alias cp='cp -iv --reflink=auto'
alias rcp='rsync -v --progress'
alias rmv='rsync -v --progress --remove-source-files'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias ln='ln -v'
alias chmod="chmod -c"
alias chown="chown -c"
alias mkdir="mkdir -v"
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'

if (( ${+commands[eza]} )); then
  alias ls='command eza --color=auto --sort=Name --classify --group-directories-first --time-style=long-iso --group'
  alias l='ls'
  alias la='ls -a'
  alias lh='ls --all --header --long'
  alias ll='lh'
else
  alias ls='command ls -C --color=auto --human-readable --classify --group-directories-first --time-style=+%Y-%m-%d\ %H:%M --quoting-style=literal'
  alias l='ls'
  alias la='ls -A'
  alias lh='la -l'
  alias ll='lh'
fi

if (( ${+commands[fd]} )); then
  alias fd='fd'
elif (( ${+commands[fdfind]} )); then
  alias fd='fdfind'
fi

if (( ${+commands[doas]} )) ; then
  alias s="doas"
else
  alias s="sudo"
fi

if (( ${+commands[systemctl]} )) ; then
  alias sdctl="systemctl"
fi

#
### End of Aliases
#

############
### Prompt
############

# Modified based on zimfw/asciiship & fff7d1bc/conf-mgmt & ohmyzsh/ohmyzsh/blob/master/themes/fishy.zsh-theme
termtitle() {
  case "$TERM" in
    rxvt*|xterm*|nxterm|gnome|screen|screen-*|st|st-*)
      local prompt_host="${(%):-%m}"
      local prompt_user="${(%):-%n}"
      local prompt_char="${(%):-%~}"
      case "$1" in
        precmd)
          printf '\e]0;%s@%s: %s\a' "${prompt_user}" "${prompt_host}" "${prompt_char}"
        ;;
        preexec)
          printf '\e]0;%s [%s@%s: %s]\a' "$2" "${prompt_user}" "${prompt_host}" "${prompt_char}"
        ;;
      esac
    ;;
  esac
}

_setup_git_prompt() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 || ! zstyle -t ':asciiship:' git-info; then
    unset git_prompt
    return 0
  fi
  local git_status=$(git --no-optional-locks status --porcelain=2 --branch --show-stash)
  local git_status_prompt=""
  if printf "${git_status}" | grep -qE '^[12] [ADRM]'; then
    git_status_prompt+="%F{2}*" # staged changes
  fi
  if printf "${git_status}" | grep -q '^?'; then
    git_status_prompt+="%F{102}U" # untracked files
  fi
  if printf "${git_status}" | grep -qE '^[12] .D'; then
    git_status_prompt+="%F{1}D" # deleted files
  fi
  if printf "${git_status}" | grep -qE '^[12] .M'; then
    git_status_prompt+="%F{14}M" # modified files
  fi
  if printf "${git_status}" | grep -qE '^[12] .R'; then
    git_status_prompt+="%F{180}R" # renamed files
  fi
  if printf "${git_status}" | grep -qE '^[12] .C'; then
    git_status_prompt+="%F{189}C" # copied files
  fi
  if printf "${git_status}" | grep -q '^u'; then
    git_status_prompt+="%F{99}!" # unmerged changes
  fi
  if printf "${git_status}" | grep -q '^# stash'; then
    git_status_prompt+="%F{139}S" # stashed changes
  fi
  local git_branch
  if printf "${git_status}" | grep -q '^# branch.head (detached)'; then
    git_branch=$(git rev-parse --short HEAD)
  else
    git_branch=$(git branch --show-current)
  fi
  if [ -z "${git_status_prompt}" ]; then
    git_prompt=" %F{white}on %F{blue}[%F{white}${git_branch}%F{blue}]%f"
  else
    git_prompt=" %F{white}on %F{blue}[%F{white}${git_branch}%F{8}:${git_status_prompt}%F{blue}]%f"
  fi
}

_get_shortened_dir() {
  local directory_parts
  directory_parts=("${(s:/:)PWD/#$HOME/~}")
  if ! zstyle -t ':asciiship:' dir-short; then
    printf "%s" "${(j:/:)directory_parts}"
    return 0
  fi
  if (( $#directory_parts > 1 )); then
    for _directory_part in {1..$(($#directory_parts-1))}; do
      if [[ "${directory_parts[$_directory_part]}" = .* ]]; then
        directory_parts[$_directory_part]="${${directory_parts[$_directory_part]}[1,2]}"
      else
        directory_parts[$_directory_part]="${${directory_parts[$_directory_part]}[1]}"
      fi
    done
  fi
  printf "%s" "${(j:/:)directory_parts}"
}

_format_execution_time() {
  local elapsed=$1
  local result=""
  local hours minutes seconds
  if [ $elapsed -gt 3600 ]; then
    hours=$((elapsed/3600))
    minutes=$(((elapsed%3600)/60))
    seconds=$((elapsed%60))
    result="${hours}h${minutes}m${seconds}s"
  elif [ $elapsed -gt 60 ]; then
    minutes=$((elapsed/60))
    seconds=$((elapsed%60))
    result="${minutes}m${seconds}s"
  else
    result="${elapsed}s"
  fi
  printf "%s" "${result}"
}

_exectime_preexec() {
  timer=$(($(date +%s)))
}

_exectime_precmd() {
  if [ $timer ]; then
    local now=$(($(date +%s)))
    local elapsed=$((now-timer))
    if [ $elapsed -gt 3 ]; then
      local time_display=$(_format_execution_time $elapsed)
      RPROMPT="%F{yellow}${time_display} %f"
    else
      RPROMPT=""
    fi
  else
    RPROMPT=""
  fi
  unset timer
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _exectime_preexec
add-zsh-hook precmd _exectime_precmd

preexec() {
  # Set terminal title along with current executed command pass as second argument
  termtitle preexec "${(V)1}"
}

precmd() {
  # Set terminal title.
  termtitle precmd
  # Set optional git part of prompt.
  _setup_git_prompt
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

PROMPT='
%(2L.%B%F{white}(%L)%f%b .)%(!.%B%F{red}%n%f%b@.${SSH_TTY:+"%B%F{blue}%n%f%b@"})${SSH_TTY:+"%B%F{blue}%m%f%b in "}%B%F{cyan}$(_get_shortened_dir)%f%b${git_prompt}%f%b${VIRTUAL_ENV:+" via %B%F{yellow}${VIRTUAL_ENV:t}%f%b"}
%B%(1j.%F{blue}*%f .)%(?.%F{green}.%F{red}%? )%#%f%b '
# RPROMPT=todo

#
### End of Prompt
#

############
### Func
############

## Modified based on MamoruDS/history-fuzzy-search
# history-fuzzy-search() {
#   local preview_extra_cmd='_fetch() { setopt extended_glob && HISTFILE='"$HISTFILE"' && fc -R && print -rNC1 -- ${(v)history[$((${(M)${*}## #<->}))]} } && _fetch {}'
#   local fuzzy_history=$(fc -lr 0 | fzf +s +m -x --with-nth 2.. --scheme=history --layout=reverse --height=50% --preview-window='bottom:3:wrap' --preview $preview_extra_cmd --query="$BUFFER")
#   if [ -n "$fuzzy_history" ]; then
#     BUFFER="${fuzzy_history[@]}"
#     zle vi-fetch-history -n $BUFFER
#   fi
#   zle reset-prompt
# }

## file find
file-fuzzy-find() {
  local fuzzy_filefind cmd keyword
  if [[ "${BUFFER}" == *" "* ]]; then
    cmd=${${BUFFER}[(w)1]}
    keyword=${BUFFER#"${cmd} "}
    fuzzy_filefind="$cmd $(eval ${FZF_DEFAULT_COMMAND} | fzf --height=50% --layout=reverse --scheme=path --query="${keyword}" +m)"
  else
    fuzzy_filefind="$(eval ${FZF_DEFAULT_COMMAND} | fzf --height=50% --layout=reverse --scheme=path --query="${BUFFER}" +m)"
  fi
  if [ -n "$fuzzy_filefind" ]; then
    BUFFER="${fuzzy_filefind[@]}"
  fi
  zle end-of-line
  zle reset-prompt
}

## sudo or doas will be inserted before the command
sudo-command-line() {
  local cmd
  [[ -z ${BUFFER} ]] && zle up-history
  if (( ${+commands[doas]} )) ; then
    cmd="doas "
  else
    cmd="sudo "
  fi
  if [[ ${BUFFER} == ${cmd}* ]]; then
    CURSOR=$(( CURSOR-${#cmd} ))
    BUFFER="${BUFFER#$cmd}"
  else
    BUFFER="${cmd}${BUFFER}"
    CURSOR=$(( CURSOR+${#cmd} ))
  fi
  zle reset-prompt
}

## File Download
xget() {
  local uri="$1"
  local save="$2"
  if [[ -z "$save" ]]; then
    save=$(basename "${uri%%\?*}")
  fi
  if (( ${+commands[aria2c]} )); then
    aria2c --max-connection-per-server=4 --continue "$uri" -o "$save"
  elif (( ${+commands[axel]} )); then
    axel --num-connections=4 --alternate "$uri" -o "$save"
  elif (( ${+commands[wget]} )); then
    wget --continue --progress=bar -O "$save" "$uri"
  elif (( ${+commands[curl]} )); then
    curl --continue-at - --location --progress-bar --remote-name --remote-time "$uri" -o "$save"
  else
    printf "No suitable download tool found.\n"
  fi
}

## smart cd function, allows switching to /etc when running 'cd /etc/fstab'
cd() {
  if (( ${#argv} == 1 )) && [[ -f ${1} ]]; then
    [[ ! -e ${1:h} ]] && return 1
    print "Correcting ${1} to ${1:h}"
    builtin cd ${1:h}
  else
    builtin cd "$@"
  fi
}

reload() {
  # clear
  exec "${SHELL}" "$@"
}

#
### End of Func
#

############
### Keybindings
############

## Editor and input char assignment
# Modified based on zimfw/input
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

# Use human-friendly identifiers.
zmodload -F zsh/terminfo +b:echoti +p:terminfo
typeset -gA key_info
key_info=(
  Control      '\C-'
  ControlLeft  '^[[1;5D'
  ControlRight '^[[1;5C'
  Escape       '\e'
  Meta         '\M-'
  Backspace    '^?'
  Delete       '^[[3~'
  BackTab      "${terminfo[kcbt]}"
  Left         "${terminfo[kcub1]}"
  Down         "${terminfo[kcud1]}"
  Right        "${terminfo[kcuf1]}"
  Up           "${terminfo[kcuu1]}"
  End          "${terminfo[kend]}"
  F1           "${terminfo[kf1]}"
  F2           "${terminfo[kf2]}"
  F3           "${terminfo[kf3]}"
  F4           "${terminfo[kf4]}"
  F5           "${terminfo[kf5]}"
  F6           "${terminfo[kf6]}"
  F7           "${terminfo[kf7]}"
  F8           "${terminfo[kf8]}"
  F9           "${terminfo[kf9]}"
  F10          "${terminfo[kf10]}"
  F11          "${terminfo[kf11]}"
  F12          "${terminfo[kf12]}"
  Home         "${terminfo[khome]}"
  Insert       "${terminfo[kich1]}"
  PageDown     "${terminfo[knp]}"
  PageUp       "${terminfo[kpp]}"
)

# Bind the keys
bindkey -e

bindkey ${key_info[ControlLeft]} backward-word
bindkey ${key_info[ControlRight]} forward-word

bindkey ${key_info[Backspace]} backward-delete-char
bindkey ${key_info[Delete]} delete-char

bindkey ${key_info[Home]} beginning-of-line
bindkey ${key_info[End]} end-of-line

bindkey ${key_info[PageUp]} up-line-or-history
bindkey ${key_info[PageDown]} down-line-or-history

bindkey ${key_info[BackTab]} reverse-menu-complete
bindkey ${key_info[Insert]} overwrite-mode

bindkey ${key_info[Left]} backward-char
bindkey ${key_info[Right]} forward-char

# Expandpace.
bindkey ' ' magic-space

# Use smart URL pasting and escaping.
autoload -Uz bracketed-paste-url-magic && zle -N bracketed-paste bracketed-paste-url-magic
autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic

# <Ctrl-e> to edit command-line in EDITOR
autoload -Uz edit-command-line && zle -N edit-command-line && \
  bindkey "${key_info[Control]}e" edit-command-line

# [Esc] [Esc] to sudo-command-line
zle -N sudo-command-line && \
  bindkey "${key_info[Escape]}${key_info[Escape]}" sudo-command-line

# <Ctrl-r> to history-fuzzy-search
# zle -N history-fuzzy-search && \
#   bindkey "${key_info[Control]}r" history-fuzzy-search

# <Ctrl-t> to file-fuzzy-find
zle -N file-fuzzy-find && \
  bindkey "${key_info[Control]}t" file-fuzzy-find

_exit_zsh() { exit; }
zle -N _exit_zsh && \
  bindkey "${key_info[Control]}d" _exit_zsh

#
### End of Keybindings
#

############
### Plugins
############

GH_MIRROR="https://github.com"

function clone_and_compile() {
  local repo_name=$1
  local repo_url=$2
  if [[ ! -e "${ZPLUGINDIR}/${repo_name}" ]]; then
    printf "Installing %s ...\n" "${repo_name}"
    command mkdir -p "${ZPLUGINDIR}/${repo_name}"
    git clone --quiet --depth=1 "${GH_MIRROR}/${repo_url}" "${ZPLUGINDIR}/${repo_name}"
    find "${ZPLUGINDIR}/${repo_name}/" -type f -name "*.zsh" -exec zsh -c "zcompile -R -- {}.zwc {} " \;
    printf "Installation %s ... completed.\n" "${repo_name}"
  fi
}

function clone_and_compile_x() {
  local repo_name="plugin"
  local repo_url="7a72/zshrc"
  if [[ ! -e "${ZPLUGINDIR}" ]]; then
    printf "Installing %s ...\n" "${repo_name}"
    command mkdir -p "${ZPLUGINDIR}"
    git clone --quiet --recursive --branch=plugin --depth=1 "${GH_MIRROR}/${repo_url}" "${ZPLUGINDIR}"
    find "${ZPLUGINDIR}/" -type f -name "*.zsh" -exec zsh -c "zcompile -R -- {}.zwc {} " \;
    printf "Installation %s ... completed.\n" "${repo_name}"
  fi
}

clone_and_compile_x

# clone_and_compile "zsh-z"                    "agkozak/zsh-z"
# clone_and_compile "zsh-completions"          "zsh-users/zsh-completions"
# clone_and_compile "completion"               "zimfw/completion"
# clone_and_compile "fzf-tab"                  "Aloxaf/fzf-tab"
# clone_and_compile "zsh-autosuggestions"      "zsh-users/zsh-autosuggestions"
# clone_and_compile "fast-syntax-highlighting" "zdharma-continuum/fast-syntax-highlighting"

function source () {
  [[ "$1.zwc" -nt $1 ]] || zcompile $1
  builtin source $@
}

function . () {
  [[ "$1.zwc" -nt $1 ]] || zcompile $1
  builtin . $@
}

fpath+="${ZPLUGINDIR}/zsh-completions/src"

ZSHZ_DATA="${ZCACHEDIR}/.z.dat"
source "${ZPLUGINDIR}/zsh-z/zsh-z.plugin.zsh"

zstyle ':completion::complete:*' cache-path "${ZCACHEDIR}/zcompcache"
zstyle ':zim:completion' dumpfile "${ZCACHEDIR}/zcompdump"
zstyle ':zim:glob' case-sensitivity sensitive
source "${ZPLUGINDIR}/completion/init.zsh"

zstyle -d ':completion:*' format
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
source "${ZPLUGINDIR}/fzf-tab/fzf-tab.zsh"

ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_STRATEGY=(completion)
ZSH_AUTOSUGGEST_HISTORY_IGNORE="(cd *|ls *|git add *)"
source "${ZPLUGINDIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"

source "${ZPLUGINDIR}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

if (( ${+commands[atuin]} )) ; then
  source "${ZPLUGINDIR}/atuin/atuin.plugin.zsh"
fi

unset RPS1

unfunction clone_and_compile clone_and_compile_x source .

#
### End of Plugins
#

############
### Misc
############

# prompt optional
zstyle ':asciiship:' git-info true
zstyle ':asciiship:' dir-short true

# Include user-specified configs.
if [ ! -d "${ZSHDDIR}" ]; then
  mkdir -p "${ZSHDDIR}" && printf "# Put your user-specified config here.\n" > "${ZSHDDIR}/example.zsh"
fi

for _zshd in $(command ls -A ${ZSHDDIR}/^*.(z)sh$); do
  . "${_zshd}"
done

#
### End of Misc
#

##### end
