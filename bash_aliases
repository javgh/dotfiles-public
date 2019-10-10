alias vi=vim
alias t='vi $HOME/todo'
pack () { cmd="tar czf $(basename $1).tar.gz $1"; echo $cmd; $cmd; }
unpack () { cmd="tar xzf $1"; echo $cmd; $cmd; }
alias adb-screenshot='adb shell screencap -p | perl -pe "s/\x0D\x0A/\x0A/g" > adb-screenshot.png'
alias b='beancount-mount; cd $HOME/main/protected/finances/beancount/'
alias twodays='remind ~/doc/reminders.rem "*2"'
alias twoweeks='remind -c+2 -w160 -m ~/doc/reminders.rem'
