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
if [ -f $HOME/.nix-profile/etc/profile.d/vte.sh ]; then
    . $HOME/.nix-profile/etc/profile.d/vte.sh
    __vte_prompt_command
fi
export TERM=xterm-256color

# autojump
autojumppath=$(autojump-share)/autojump.bash
if [ -f $autojumppath ]; then
    . $autojumppath
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
