#!/bin/bash

# set some folders and permissions

[[ -f $PGCONF/postgresql.conf ]] && (chown abc:abc $PGCONF/postgresql.conf \
&& chmod 666 $PGCONF/postgresql.conf)

[[ ! -d $MBDATA || ! -d $PGDATA ]] && (mkdir -p $MBDATA $PGDATA && chown -R abc:abc $DATA_ROOT)

mkdir -p /var/run/postgresql
chown -R abc:abc /var/run/postgresql /app

set -e

set_listen_addresses() {
	sedEscapedValue="$(echo "*" | sed 's/[\/&]/\\&/g')"
	sed -ri "s/^#?(listen_addresses\s*=\s*)\S+/\1'$sedEscapedValue'/" "$PGDATA/postgresql.conf"
}

# initialise empty database structure and change temporary ownership config files
if [ ! -s "$PGDATA/PG_VERSION" ]; then
echo "initialising empty databases"
/sbin/setuser abc initdb >/dev/null 2>&1
echo "completed postgres initialise"

echo "local   all    all    trust" >> "$PGDATA/pg_hba.conf"
echo "host all  all    0.0.0.0/0  md5" >> "$PGDATA/pg_hba.conf"
set_listen_addresses ''

/sbin/setuser abc postgres  >/dev/null 2>&1 &
pid="$!"
sleep 5s
/sbin/setuser abc createdb  >/dev/null 2>&1
/sbin/setuser abc psql --command "ALTER USER abc WITH SUPERUSER 'abc';"  >/dev/null 2>&1
sleep 5s

#dumpver=$(curl -s $URL_ROOT/LATEST)
dumpver=20151202-005921

DUMP_URL="$URL_ROOT"/"$dumpver"

/sbin/setuser abc curl -o "$MBDATA"/MD5SUMS -L -C - "$DUMP_URL"/MD5SUMS
/sbin/setuser abc curl -o "$MBDATA"/mbdump-cdstubs.tar.bz2 -L -C - "$DUMP_URL"/mbdump-cdstubs.tar.bz2
/sbin/setuser abc curl -o "$MBDATA"/mbdump-cover-art-archive.tar.bz2 -L -C - "$DUMP_URL"/mbdump-cover-art-archive.tar.bz2
/sbin/setuser abc curl -o "$MBDATA"/mbdump-derived.tar.bz2 -L -C - "$DUMP_URL"/mbdump-derived.tar.bz2
/sbin/setuser abc curl -o "$MBDATA"/mbdump-editor.tar.bz2 -L -C - "$DUMP_URL"/mbdump-editor.tar.bz2
/sbin/setuser abc curl -o "$MBDATA"/mbdump-sitemaps.tar.bz2 -L -C - "$DUMP_URL"/mbdump-sitemaps.tar.bz2
/sbin/setuser abc curl -o "$MBDATA"/mbdump-stats.tar.bz2 -L -C - "$DUMP_URL"/mbdump-stats.tar.bz2
/sbin/setuser abc curl -o "$MBDATA"/mbdump-wikidocs.tar.bz2 -L -C - "$DUMP_URL"/mbdump-wikidocs.tar.bz2
/sbin/setuser abc curl -o "$MBDATA"/mbdump.tar.bz2 -L -C - "$DUMP_URL"/mbdump.tar.bz2
pushd /data/import && md5sum -c MD5SUMS && popd
cd /app/musicbrainz
/sbin/setuser abc ./admin/InitDb.pl --createdb --import /data/import/mbdump*.tar.bz2 --tmp-dir /data/import --echo

kill "$pid"  >/dev/null 2>&1
wait "$pid"
set_listen_addresses '*'
fi

mkdir -p "$PGCONF"
if [ ! -f "$PGCONF/postgresql.conf" ]; then
cp "$PGDATA"/postgresql.conf "$PGCONF"/postgresql.conf
chown abc:abc "$PGCONF"/postgresql.conf
chmod 666 "$PGCONF"/postgresql.conf
fi

