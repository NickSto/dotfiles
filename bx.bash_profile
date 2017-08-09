# Use a special variable to set the ultimate destination when accessing bx through uniport.
if [[ $(hostname) == uniport ]] && [[ $LC_BX_DEST ]]; then
  ssh $LC_BX_DEST
fi

# Allow me to remotely turn off auto-screen even if I have trouble setting $TERM.
if [[ -f ~/NOSCREEN ]]; then
  LC_NO_SCREEN=true
fi

if [[ -d /galaxy/home/$USER ]]; then
  export HOME=/galaxy/home/$USER
  cd $HOME
fi

source .bashrc
