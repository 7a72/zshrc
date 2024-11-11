#!/usr/bin/env zsh

##### .zshrc

PS1="Ready > "
RPS1="%F{240}Loading...%f"

############
### Environment
############

ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
ZSHDDIR="${ZDOTDIR}/conf.d"
ZDATADIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
ZCACHEDIR="${ZDATADIR}/cache"
[ -d "${ZCACHEDIR}" ] || mkdir -p "${ZCACHEDIR}"

[[ ":$PATH:" == *":$HOME/bin:"* ]] || export PATH="${HOME}/bin:$PATH"

if [[ $(tty) == /dev/tty* ]] ; then
  export LANG=C.UTF-8
elif [[ $(tty) == /dev/pts/* ]] ; then
  export LANG=zh_CN.UTF-8
fi

if (($+commands[gpg])); then
  export GPG_TTY=$(tty)
fi

if [[ -z ${EDITOR} ]]; then
  for editor in hx nvim vim nano; do
    if (($+commands[$editor])); then
      export EDITOR="$editor"
      # export VISUAL=$EDITOR
      break
    fi
  done
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
HISTFILE="${ZCACHEDIR}/zsh_history"
HISTSIZE='16384'
SAVEHIST='16384'
setopt append_history
setopt extended_history
setopt inc_append_history
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt hist_verify
setopt share_history

#
### End of Features
#

############
### Prompt
############

# Modified based on zimfw/asciiship & fff7d1bc/conf-mgmt
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

setup_git_prompt() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 || ! zstyle -t ':asciiship:' git-info; then
    unset git_prompt
    return 0
  fi

  local git_status_stash=""
  local git_branch=""
  local git_status_committed=""
  local git_status_untracked=""
  local git_status_deleted=""
  local git_status_modified=""
  local git_status_renamed=""
  local git_status_copied=""
  local git_status_conflicted=""

  local status_output
  status_output=$(git --no-optional-locks status --porcelain)

  echo "$status_output" | grep -qE '^[AM]' && git_status_committed='%F{green}*'
  echo "$status_output" | grep -q '^??' && git_status_untracked='%F{red}U'
  echo "$status_output" | grep -q '^ D' && git_status_deleted='%F{yellow}D'
  echo "$status_output" | grep -q '^ M' && git_status_modified='%F{cyan}M'
  echo "$status_output" | grep -q '^ R' && git_status_renamed='%F{magenta}R'
  echo "$status_output" | grep -q '^ C' && git_status_copied='%F{blue}C'
  echo "$status_output" | grep -q '^[U]' && git_status_conflicted='%F{red}!'
  [ "$(git stash list)" ] && git_status_stash="%F{yellow}S"

  git_branch=$(git branch --show-current 2>/dev/null)
  if [ -z "$git_branch" ]; then
    git_branch=$(git rev-parse --short HEAD 2>/dev/null)
      if [ -z "$git_branch" ]; then
        git_branch='^HEAD'
      fi
  fi

  local status_string="${git_status_committed}${git_status_untracked}${git_status_deleted}${git_status_modified}${git_status_renamed}${git_status_copied}${git_status_conflicted}${git_status_stash}"
  status_string="${status_string//:/:}"

  git_prompt=" on %F{blue}[%F{253}${git_branch}${status_string:+:$status_string}%F{blue}]"
}

precmd() {
  # Set terminal title.
  termtitle precmd
  # Set optional git part of prompt.
  setup_git_prompt
}
preexec() {
  # Set terminal title along with current executed command pass as second argument
  termtitle preexec "${(V)1}"
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

shorten_path() {
  local long_path="${1/#$HOME/~}"

  if ! zstyle -t ':asciiship:' shorten-path; then
    echo $long_path
    return 0
  fi

  local path_length="${#long_path}"

  if [ ${path_length} -gt 16 ]; then
    IFS='/' read -r -A path_parts <<< "$long_path"
    if [ ${#path_parts[@]} -le 2 ]; then
      echo "$long_path"
    else
      printf "%s" "${path_parts[0]}"
      for ((i=1; i<${#path_parts[@]}-1; i++)); do
        printf "/%s" "${path_parts[$i]:0:1}"
      done
      printf "/%s\n" "${path_parts[-1]}"
    fi
  else
    echo "$long_path"
  fi
}

PROMPT='
%(2L.%B%F{white}(%L)%f%b .)%(!.%B%F{red}%n%f%b@.${SSH_TTY:+"%B%F{blue}%n%f%b@"})${SSH_TTY:+"%B%F{blue}%m%f%b in "}%B%F{cyan}$(shorten_path "$PWD")%f%b${git_prompt}%f%b${VIRTUAL_ENV:+" via %B%F{yellow}${VIRTUAL_ENV:t}%f%b"}
%B%(1j.%F{blue}*%f .)%(?.%F{green}.%F{red}%? )%#%f%b '
# RPROMPT=todo

#
### End of Prompt
#

############
### Plugins
############

GH_MIRROR="https://github.com"

function zcompile-many() {
  local f
  for f; do zcompile -R -- "$f".zwc "$f"; done
}

if [[ ! -e ${ZDATADIR}/zsh-defer ]]; then
  mkdir -p ${ZDATADIR}/zsh-defer
  git clone --depth=1 ${GH_MIRROR}/romkatv/zsh-defer.git ${ZDATADIR}/zsh-defer
  zcompile-many ${ZDATADIR}/zsh-defer/zsh-defer.plugin.zsh
fi
source ${ZDATADIR}/zsh-defer/zsh-defer.plugin.zsh

if [[ ! -e ${ZDATADIR}/fast-syntax-highlighting ]]; then
  mkdir -p ${ZDATADIR}/fast-syntax-highlighting
  git clone --depth=1 ${GH_MIRROR}/zdharma-continuum/fast-syntax-highlighting ${ZDATADIR}/fast-syntax-highlighting
  zcompile-many ${ZDATADIR}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

if [[ ! -e ${ZDATADIR}/history-search-multi-word ]]; then
  mkdir -p ${ZDATADIR}/history-search-multi-word
  git clone --depth=1 ${GH_MIRROR}/zdharma-continuum/history-search-multi-word ${ZDATADIR}/history-search-multi-word
  zcompile-many ${ZDATADIR}/history-search-multi-word/history-search-multi-word.plugin.zsh
fi

if [[ ! -e ${ZDATADIR}/zsh-autosuggestions ]]; then
  mkdir -p ${ZDATADIR}/zsh-autosuggestions
  git clone --depth=1 ${GH_MIRROR}/zsh-users/zsh-autosuggestions.git ${ZDATADIR}/zsh-autosuggestions
  zcompile-many ${ZDATADIR}/zsh-autosuggestions/{zsh-autosuggestions.zsh,src/**/*.zsh}
fi

if [[ ! -e ${ZDATADIR}/zsh-z ]]; then
  mkdir -p ${ZDATADIR}/zsh-z
  git clone --depth=1 ${GH_MIRROR}/agkozak/zsh-z.git ${ZDATADIR}/zsh-z
  zcompile-many ${ZDATADIR}/zsh-z/{zsh-z.plugin.zsh,_zshz}
fi

if [[ ! -e ${ZDATADIR}/zsh-completions ]]; then
  mkdir -p ${ZDATADIR}/zsh-completions
  git clone --depth=1 ${GH_MIRROR}/zsh-users/zsh-completions.git ${ZDATADIR}/zsh-completions
  zcompile-many ${ZDATADIR}/zsh-completions/{zsh-completions.plugin.zsh,src/*}
fi

if [[ ! -e ${ZDATADIR}/fzf-tab ]]; then
  mkdir -p ${ZDATADIR}/fzf-tab
  git clone --depth=1 ${GH_MIRROR}/Aloxaf/fzf-tab.git ${ZDATADIR}/fzf-tab
  zcompile-many ${ZDATADIR}/fzf-tab/{fzf-tab.*,lib/**/*.zsh}
fi

# Load and initialize the completion system
source ${ZDATADIR}/zsh-completions/zsh-completions.plugin.zsh
autoload -Uz compinit && compinit -C -d ${ZCACHEDIR}/zcompdump
[[ ${ZCACHEDIR}/zcompdump.zwc -nt ${ZCACHEDIR}/zcompdump ]] || zcompile ${ZCACHEDIR}/zcompdump

unfunction zcompile-many

ZSHZ_DATA="${ZCACHEDIR}/zshz.dat"
zsh-defer source ${ZDATADIR}/zsh-z/zsh-z.plugin.zsh
zsh-defer source ${ZDATADIR}/fzf-tab/fzf-tab.plugin.zsh
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
zsh-defer source ${ZDATADIR}/zsh-autosuggestions/zsh-autosuggestions.zsh
typeset -gA FAST_HIGHLIGHT
FAST_HIGHLIGHT[git-cmsg-len]=100
zsh-defer source ${ZDATADIR}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
zsh-defer source ${ZDATADIR}/history-search-multi-word/history-search-multi-word.plugin.zsh
zsh-defer -c 'unset RPS1'

#
### End of Plugins
#

############
### Misc
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

if [[ -n ${key_info[Home]} ]] bindkey ${key_info[Home]} beginning-of-line
if [[ -n ${key_info[End]} ]] bindkey ${key_info[End]} end-of-line

if [[ -n ${key_info[PageUp]} ]] bindkey ${key_info[PageUp]} up-line-or-history
if [[ -n ${key_info[PageDown]} ]] bindkey ${key_info[PageDown]} down-line-or-history

if [[ -n ${key_info[BackTab]} ]] bindkey ${key_info[BackTab]} reverse-menu-complete
if [[ -n ${key_info[Insert]} ]] bindkey ${key_info[Insert]} overwrite-mode

if [[ -n ${key_info[Left]} ]] bindkey ${key_info[Left]} backward-char
if [[ -n ${key_info[Right]} ]] bindkey ${key_info[Right]} forward-char

# Expandpace.
bindkey ' ' magic-space

# Use smart URL pasting and escaping.
autoload -Uz bracketed-paste-url-magic && zle -N bracketed-paste bracketed-paste-url-magic
autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic

# <Ctrl-r> to history-search-multi-word
bindkey "${key_info[Control]}r" history-search-multi-word

# <Ctrl-e> to edit command-line in EDITOR
autoload -Uz edit-command-line && zle -N edit-command-line && \
  bindkey "${key_info[Control]}e" edit-command-line

# prompt optional
zstyle ':asciiship:' git-info true
zstyle ':asciiship:' shorten-path true

# fzf-tab optional
zstyle -d ':completion:*' format
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

#
### End of Misc
#

############
### Func
############

## sudo or doas will be inserted before the command
sudo-command-line() {
  [[ -z $BUFFER ]] && zle up-history

  if (( $+commands[doas] )) ; then
    local cmd="doas "
  else
    local cmd="sudo "
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
zle -N sudo-command-line
# Defined shortcut keys: [Esc] [Esc]
bindkey "${key_info[Escape]}${key_info[Escape]}" sudo-command-line

## File Download
get() {
  local uri="$1"
  local save="$2"

  if (( ${+commands[aria2c]} )); then
    aria2c --max-connection-per-server=5 --continue "$uri" -o "$save"
  elif (( ${+commands[axel]} )); then
    axel --num-connections=5 --alternate "$uri" -o "$save"
  elif (( ${+commands[wget]} )); then
    wget --continue --progress=bar --timestamping -O "$save" "$uri"
  elif (( ${+commands[curl]} )); then
    curl --continue-at - --location --progress-bar --remote-name --remote-time "$uri" -o "$save"
  else
    echo "No suitable download tool found."
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

exit_zsh() { exit }
zle -N exit_zsh
bindkey "${key_info[Control]}d" exit_zsh

#
### End of Func
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

if (( $+commands[eza] )); then
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

#
### End of Aliases
#

# Include user-specified configs.
if [ ! -d "${ZSHDDIR}" ]; then
    mkdir -p "${ZSHDDIR}" && echo "# Put your user-specified config here." > "${ZSHDDIR}/example.zsh"
fi

for zshd in $(ls -A ${ZSHDDIR}/^*.(z)sh$); do
  . "${zshd}"
done

##### end