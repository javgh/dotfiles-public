alias t='vi $HOME/todo'
pack () { cmd="tar czf $(basename $1).tar.gz $1"; echo $cmd; $cmd; }
unpack () { cmd="tar xzf $1"; echo $cmd; $cmd; }
