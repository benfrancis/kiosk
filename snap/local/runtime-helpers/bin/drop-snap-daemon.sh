#!/bin/bash -ex
# setup a $SNAP_USER_DATA under $SNAP_DATA for snap-daemon user
mkdir -p $SNAP_DATA/snap-daemon-home/.config
chown  snap_daemon:snap_daemon $SNAP_DATA/snap-daemon-home
chown  snap_daemon:snap_daemon $SNAP_DATA/snap-daemon-home/.config

# set XDG_CONFIG_HOME to use our $SNAP_USER_DATA (needed by Electron)
XDG_CONFIG_HOME=$SNAP_DATA/snap-daemon-home/.config 
export XDG_CONFIG_HOME

# maybe this is unnecessary, but just to be safe if electron needs $HOME for anything else
HOME=$SNAP_DATA/snap-daemon-home
export HOME

exec "$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "$@"
