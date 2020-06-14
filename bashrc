# give history some space
HISTSIZE=10000
HISTFILESIZE=10000

# share history
shopt -s histappend
PROMPT_COMMAND="$PROMPT_COMMAND; history -a"

# no duplicate entries
export HISTCONTROL=ignoredups

# umask (remove rights for group & others)
umask 077

# termite
export TERM=xterm-256color

# calculator
c () {
    echo "$@" | bc -l
}

# editor
vimpath=$(which vim)
if [ -f "$vimpath" ]; then
    export EDITOR="$vimpath"
fi

# disable XON/XOFF flow control
# to allow vim to see Ctrl+S
case "$TERM" in
    xterm*) stty -ixon
esac

# browser
chromiumpath=$(which chromium)
if [ -f "$chromiumpath" ]; then
    export BROWSER="$chromiumpath"
fi

# NPM
export NPM_CONFIG_PREFIX=$HOME/.npm-global
export PATH=$PATH:$HOME/.npm-global/bin

# solarized dircolors
eval `dircolors $HOME/.dircolors.ansi-universal`

# aliases
if [ -f $HOME/.bash_aliases ]; then
    . $HOME/.bash_aliases
fi
