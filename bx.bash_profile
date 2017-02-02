
if [[ -f ~/NOSCREEN ]]; then
  TERM=noscreen
fi

if [[ -d /galaxy/home/$USER ]]; then
  export HOME=/galaxy/home/$USER
  cd $HOME
fi

source .bashrc

