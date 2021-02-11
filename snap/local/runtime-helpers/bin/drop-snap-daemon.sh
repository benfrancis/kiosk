#!/bin/bash -ex

# Create data directories needed by Electron
mkdir -p $SNAP_DATA/snap-daemon-home
mkdir -p $SNAP_DATA/snap-daemon-home/.config
if [[ ! -d $SNAP_DATA/snap-daemon-home/.cache ]]
then
  # Copy .cache directory to somewhere snap_daemon can access
  cp -r $SNAP_USER_COMMON/.cache $SNAP_DATA/snap-daemon-home/
fi

# Give snap_daemon ownership over data directories
chown snap_daemon:snap_daemon $SNAP_DATA/snap-daemon-home
chown snap_daemon:snap_daemon $SNAP_DATA/snap-daemon-home/.config
chown -R snap_daemon:snap_daemon $SNAP_DATA/snap-daemon-home/.cache

# Tell Electron where to find data directories
export HOME=$SNAP_DATA/snap-daemon-home
export XDG_CONFIG_HOME=$SNAP_DATA/snap-daemon-home/.config
export XDG_CACHE_HOME=$SNAP_DATA/snap-daemon-home/.cache
export GDK_PIXBUF_MODULE_FILE=$XDG_CACHE_HOME/gdk-pixbuf-loaders.cache

# Give the snap_daemon user access to the X server
xhost si:localuser:snap_daemon

# Execute the rest of the command chain as the snap_daemon user
exec "$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "$@"
