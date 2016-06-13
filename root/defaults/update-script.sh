#!/bin/bash

export X=X

UPDATER_LOG_DIR=/config/log/musicbrainz
mkdir -p $UPDATER_LOG_DIR
touch $UPDATER_LOG_DIR/slave.log
chown -R abc:abc $UPDATER_LOG_DIR
cd /app/musicbrainz || exit
eval "$(./admin/ShowDBDefs)"

X=${SLAVE_LOG:=$UPDATER_LOG_DIR/slave.log}
X=${LOGROTATE:=/usr/sbin/logrotate --state $UPDATER_LOG_DIR/.logrotate-state}
./admin/replication/LoadReplicationChanges >> "$SLAVE_LOG" 2>&1 || {
    RC=$?
    echo "$(date)"" : LoadReplicationChanges failed (rc=$RC) - see $SLAVE_LOG"
}
$LOGROTATE /dev/stdin <<EOF
$SLAVE_LOG {
    daily
    rotate 30
}
EOF
#eof
