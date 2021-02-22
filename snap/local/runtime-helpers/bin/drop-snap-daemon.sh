#!/bin/bash -ex

SNAP_DAEMON_HOME=$SNAP_DATA/snap-daemon-home

# Create snap_daemon "home" for writing by `setpriv` process
mkdir -p $SNAP_DAEMON_HOME

# If the snap has updated since snap_daemon's home was made,
# ensure we copy across the updates
# We can't use $SNAP_USER_DATA/.last_revision as that is already the latest
# version, so we keep a copy for ourselves
UPDATE_REQUIRED=true
if [[ -f $SNAP_DAEMON_HOME/.last_revision ]]
then
  . $SNAP_DAEMON_HOME/.last_revision 2>/dev/null || true
  if [[ "$SNAP_DESKTOP_LAST_REVISION" = "$SNAP_REVISION" ]]
  then
    UPDATE_REQUIRED=false
  fi
fi

if [[ "$UPDATE_REQUIRED" = "true" ]]
then
  cp $SNAP_USER_DATA/.last_revision $SNAP_DAEMON_HOME/.last_revision
fi

# Copy across directories created by `desktop-launch` that Electron needs to run
if [[ ! -d $SNAP_DAEMON_HOME/.cache || "$UPDATE_REQUIRED" = "true" ]]
then
  # Copy .cache directory to somewhere snap_daemon can access
  cp -r $SNAP_USER_COMMON/.cache $SNAP_DAEMON_HOME
fi
if [[ ! -d $SNAP_DAEMON_HOME/.config || "$UPDATE_REQUIRED" = "true" ]]
then
  # Copy .config directory to somewhere snap_daemon can access
  cp -r $SNAP_USER_DATA/.config $SNAP_DAEMON_HOME
fi
if [[ ! -d $SNAP_DAEMON_HOME/.local || "$UPDATE_REQUIRED" = "true" ]]
then
  # Copy .local directory to somewhere snap_daemon can access
  cp -r $SNAP_USER_DATA/.local $SNAP_DAEMON_HOME
fi

# Give snap_daemon ownership over data directories
if [[ "$UPDATE_REQUIRED" = "true" ]]
then
  chown -R snap_daemon:snap_daemon $SNAP_DAEMON_HOME
fi

# Tell Electron where to find data directories
export HOME=$SNAP_DAEMON_HOME
export XDG_CONFIG_HOME=$SNAP_DAEMON_HOME/.config
export XDG_CACHE_HOME=$SNAP_DAEMON_HOME/.cache
export XDG_DATA_HOME=$SNAP_DAEMON_HOME/.local/share
export XDG_DATA_DIRS=$XDG_DATA_HOME:$SNAP_DATA:$SNAP/usr/share

# This is all from desktop-launch and we need to re-set them for the new home
export GDK_PIXBUF_MODULE_FILE=$XDG_CACHE_HOME/gdk-pixbuf-loaders.cache
export GTK_IM_MODULE_FILE=$XDG_CACHE_HOME/immodules/immodules.cache
export GIO_MODULE_DIR=$XDG_CACHE_HOME/gio-modules

# Give the snap_daemon user access to the X server
xhost si:localuser:snap_daemon

# Change to $SNAP/snap-daemon-home to allow Electron write access
cd $SNAP_DAEMON_HOME

# Execute the rest of the command chain as the snap_daemon user
exec "$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "$@"
