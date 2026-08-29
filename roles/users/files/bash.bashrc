# System-wide .bashrc file for interactive bash(1) shells.
#
# This only sets the handful of things that should apply before a user's own
# ~/.bashrc loads (see roles/users/files/skel/.bashrc). All prompt, color,
# alias, and history customization lives there instead of being duplicated
# here — ~/.bashrc runs after this file and would just override it anyway.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
shopt -s histappend

# enable bash completion in interactive shells
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
