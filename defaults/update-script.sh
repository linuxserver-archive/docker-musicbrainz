#!/bin/bash
UPDATER_LOG_DIR=/config/updater-logs
mkdir -p $UPDATER_LOG_DIR
touch $UPDATER_LOG_DIR/slave.log
cd /app/musicbrainz
eval `./admin/ShowDBDefs`
X=${SLAVE_LOG:=$UPDATER_LOG_DIR/slave.log}
X=${LOGROTATE:=/usr/sbin/logrotate --state $UPDATER_LOG_DIR/.logrotate-state}
./admin/replication/LoadReplicationChanges >> $SLAVE_LOG 2>&1 || {
    RC=$?
    echo `date`" : LoadReplicationChanges failed (rc=$RC) - see $SLAVE_LOG"
}
$LOGROTATE /dev/stdin <<EOF
$SLAVE_LOG {
    daily
    rotate 30
}
EOF
# eof
