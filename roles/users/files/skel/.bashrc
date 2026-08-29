# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History ------------------------------------------------------------
# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=ignoreboth
# Keep a long scrollback: plain bash history, no external history manager.
export HISTSIZE=10000
export HISTFILESIZE=10000
# Set history date/time format
export HISTTIMEFORMAT="%Y.%m.%d-%H:%M:%S "
# Remove some basic commands from history
export HISTIGNORE="ls:cd:[bf]g:exit:..:...:l:cl"
# Causes bash to append history instead of overwriting it
shopt -s histappend
# Merge history live across every open terminal: append this shell's new
# lines, drop the in-memory list, then reread the file so each shell sees
# what every other shell just wrote. RET=$? is captured first since it's
# also used by the prompt below, and must run before anything else touches $?.
PROMPT_COMMAND='RET=$?; history -a; history -c; history -r'
# Allow ctrl-S for history navigation (with ctrl-R)
stty -ixon

# Enable bash completion.
[ -f /etc/bash_completion ] && source /etc/bash_completion

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Load aliases if they exist.
[ -f "${HOME}/.aliases" ] && source "${HOME}/.aliases"
[ -f "${HOME}/.aliases.local" ] && source "${HOME}/.aliases.local"

# Load local bashrc if it exist.
[ -f "${HOME}/.bashrc.local" ] && source "${HOME}/.bashrc.local"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# SSH Agent -----------------------------------------------------------
# Ensure an ssh-agent is running so keys can be forwarded on to further
# hosts. Skipped when SSH_AUTH_SOCK is already set (e.g. this session came
# in over `ssh -A`) so a forwarded agent is never shadowed by a fresh local
# one. The agent's env is cached in SSH_ENV so every terminal reuses the
# same agent process instead of spawning a new one per shell.
SSH_ENV="${HOME}/.ssh/agent.env"
if [ -z "$SSH_AUTH_SOCK" ]; then
    [ -f "$SSH_ENV" ] && source "$SSH_ENV" > /dev/null
    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        (umask 077; ssh-agent -s > "$SSH_ENV")
        source "$SSH_ENV" > /dev/null
    fi
    ssh-add -l > /dev/null 2>&1 || ssh-add > /dev/null 2>&1
fi

# Set the default editor -------------------------------------------
export EDITOR=vim
export VISUAL=vim

export TERM=xterm-256color
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Add colors to the less and man commands.
export LESS=-R
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"; a="${a%_}"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"; a="${a%_}"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"; a="${a%_}"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"; a="${a%_}"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"; a="${a%_}"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"; a="${a%_}"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"; a="${a%_}"

# Set xTerm Title --------------------------------------------------
# If this is an xterm set the title to host:dir for easier readability
case "$TERM" in
  xterm*|rxvt*)
    XTERM_TITLE='\[\033]0;\u@\h:\w\007\]';
  ;;
  *)
  ;;
esac

# Input stuff -------------------------------------------------------
bind "set completion-ignore-case on" # note: bind used instead of sticking these in .inputrc
bind "set show-all-if-ambiguous On" # show list automatically, without double tab
bind "set bell-style none" # no bell

set -o emacs                # Emacs mode
set -o noclobber            # dont inadvertently overwrite files
shopt -s autocd             # change to named directory
shopt -s cdable_vars        # if cd arg is not valid, assumes its a var defining a dir
shopt -s cdspell            # autocorrects cd misspellings
shopt -s checkwinsize       # update the value of LINES and COLUMNS after each command if altered
shopt -s cmdhist            # save multi-line commands in history as single line
shopt -s dotglob            # include dotfiles in pathname expansion
shopt -s expand_aliases     # expand aliases
shopt -s extglob            # enable extended pattern-matching features
shopt -s globstar           # recursive globbing
shopt -s progcomp           # programmable completion
shopt -s hostcomplete       # attempt hostname expansion when @ is at the beginning of a word
shopt -s nocaseglob         # pathname expansion will be treated as case-insensitive

# Command Not Found ------------------------------------------------
# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found ]; then
  if [ -x /usr/bin/python3 ]; then
    function command_not_found_handle {
      # check because c-n-f could've been removed in the meantime
      if [ -x /usr/lib/command-not-found ]; then
        /usr/bin/python3 /usr/lib/command-not-found -- $1
        return $?
      elif [ -x /usr/share/command-not-found ]; then
        /usr/bin/python3 /usr/share/command-not-found -- $1
        return $?
      else
        return 127
      fi
    }
  fi
fi

# Prompt -----------------------------------------------------------
# Colors used in the prompt below. Root gets a red prompt, everyone else
# gets a green one, so it's obvious at a glance whether a shell is root.
export COLOR_NC='\[\e[0m\]' # No Color
export COLOR_WHITE='\[\e[0;37m\]'
export COLOR_GREEN='\[\e[0;32m\]'
export COLOR_CYAN='\[\e[0;36m\]'
export COLOR_RED='\[\e[0;31m\]'
export COLOR_PURPLE='\[\e[0;35m\]'

unset color_prompt force_color_prompt

PIPE="$COLOR_RED|$COLOR_WHITE"
RET_FAIL='$(if [[ $RET != 0 ]]; then echo -ne "'"$COLOR_RED"'| (\$?=$RET)"; fi;)'
JOBS="Jobs:\j"
case $(id -u) in
  0)
PS1="$XTERM_TITLE\
$COLOR_PURPLE\D{%F %T} $PIPE $JOBS $PIPE $COLOR_RED\u@\H $RET_FAIL \n\
$COLOR_RED\w$COLOR_NC\$ "
  ;;
  *)
PS1="$XTERM_TITLE\n\
$COLOR_PURPLE\D{%F %T} $PIPE $JOBS $PIPE $COLOR_GREEN\u@\H $RET_FAIL \n\
$COLOR_CYAN\w$COLOR_NC\$ "
  ;;
esac
