# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
    # Shell is non-interactive.  Be done now!
    return
fi
# Put your fun stuff here.
export HISTCONTROL=ignoreboth
export HISTSIZE=5000
shopt -s histappend
export PS1='\[\033[01;32m\][\h]\[\033[01;34m\]\w\$ \[\033[00m\]'

#export LC_ALL=''
export EDITOR="nano -w"
export VISUAL="nano -w"
umask 0002

alias ls='ls -F --color=auto'
alias calc='python3 -ic "from math import *"'
alias time='/usr/bin/time -f"Elapsed time: %E"'
