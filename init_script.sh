#!/bin/sh

# content of /etc/init.d/laclasse-cahiertextes

### BEGIN INIT INFO
# Provides:          laclasse-cahiertextes
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      S 0 1 6
# Short-Description: cahiertextes  initscript
# Description:       cahiertextes laclasse.com
### END INIT INFO

# (c) ERASME / laclasse.com

# Do NOT "set -e"

APP=laclasse-cahiertextes
APP_PATH=~erasme/${APP}
DAEMON="${APP_PATH}/bin/puma"
CONTROL="${APP_PATH}/bin/pumactl"

SCRIPT_NAME=/etc/init.d/${APP}

ARGS="--daemon -C${APP_PATH}/config/puma.rb ${APP_PATH}/config.ru"
CONTROL_ARGS="-F${APP_PATH}/config/puma.rb "

# Creates PID dir (this dir is in tmps, so it needs to be created at every boot)
if [ -e /var/run/ ]; then
    mkdir -p /var/run/${APP}
    chown erasme /var/run/${APP}
fi

. /lib/init/vars.sh

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0
[ -x "$CONTROL" ] || exit 0

case "$1" in
    start)
        su - erasme -c "$DAEMON $ARGS"
        ;;
    stop)
        su - erasme -c "$CONTROL $CONTROL_ARGS stop"
        ;;
    restart)
        su - erasme -c "$CONTROL $CONTROL_ARGS restart"
        ;;
    *)
        echo "Usage: $SCRIPT_NAME {start|stop|restart}" >&2
        exit 3
        ;;
esac
