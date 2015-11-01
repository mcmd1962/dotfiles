# .profile

export EDITOR=/usr/bin/vim
#export ENV=$HOME/.kshrc

HOMETMP=~marcel
[ ! -r $HOMETMP/.alias.global ]  &&  HOMETMP=/tmp/marcel
export HOMETMP

if [ "X$SSH_AUTH_SOCK" = "X" ]; then
   # set the SSH_AUTH_SOCK when possible
   if [ "X$USER" = "X" ]; then
      USER=$USERNAME
   fi
   export SSH_AUTH_SOCK=`ls -ltr /tmp/ssh-*/agent* 2> /dev/null | grep $USER | tail -1 | grep ^s | awk '{print $9}' `
fi

# good moment to see whether we want to source a local .profile file
if [ -r $HOMETMP/.profile.local ]; then
   . $HOMETMP/.profile.local
fi

case `uname -s` in
          Linux)  test -r $HOMETMP/.bashrc  && . $HOMETMP/.bashrc  ;;
          SunOS)  test -r $HOMETMP/.bashrc  && . $HOMETMP/.bashrc  ;;
          *)       ;;
esac

