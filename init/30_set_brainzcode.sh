#!/bin/bash

[[ ! -f /config/DBDefs.pm ]] && cp /defaults/DBDefs.pm /config/DBDefs.pm
[[ ! -L /app/musicbrainz/lib/DBDefs.pm && -f /app/musicbrainz/lib/DBDefs.pm ]] && rm /app/musicbrainz/lib/DBDefs.pm
[[ ! -L /app/musicbrainz/lib/DBDefs.pm ]] && ln -s /config/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm

# sanitize brainzcode for white space
SANEDBRAINZCODE0=$BRAINZCODE
SANEDBRAINZCODE1="${SANEDBRAINZCODE0#"${SANEDBRAINZCODE0%%[![:space:]]*}"}"
SANEDBRAINZCODE="${SANEDBRAINZCODE1%"${SANEDBRAINZCODE1##*[![:space:]]}"}"
sed -i "s|\(sub REPLICATION_ACCESS_TOKEN\ {\ \\\"\)[^<>]*\(\\\"\ }\)|\1${SANEDBRAINZCODE}\2|" /config/DBDefs.pm

chown abc:abc /config/DBDefs.pm
