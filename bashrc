# give history some space
HISTSIZE=10000
HISTFILESIZE=10000

# share history
shopt -s histappend
PROMPT_COMMAND="history -a"

# no duplicate entries
export HISTCONTROL=ignoredups

# umask (remove rights for group & others)
umask 077

# let termite retain cwd; needs to be before autojump script,
# as it overwrites PROMPT_COMMAND and then prevents autojump
# from updating its database
if [ -f "$VTE_NG_PATH/etc/profile.d/vte.sh" ]; then
    . "$VTE_NG_PATH/etc/profile.d/vte.sh"
    __vte_prompt_command
fi
export TERM=xterm-256color

# autojump
if [ -f "$AUTOJUMP_PATH/share/autojump/autojump.bash" ]; then
    . "$AUTOJUMP_PATH/share/autojump/autojump.bash"
fi

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
