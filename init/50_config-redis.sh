#!/bin/bash
mkdir -p /var/lib/redis /var/log/redis

# If redi.conf file is missing copy one from the default
if [ ! -f /config/redis.conf ]; then
  cp /etc/redis/redis.conf /config/redis.conf
  chown abc:abc /config/redis.conf && chmod 774 /config/redis.conf
  sed 's/^daemonize yes/daemonize no/' -i /config/redis.conf
  sed 's/^bind 127.0.0.1/bind 0.0.0.0/' -i /config/redis.conf
  sed 's/^logfile \/var\/log\/redis\/redis-server.log/logfile \"\"/' -i /config/redis.conf
fi

chown -R abc:abc /var/lib/redis /var/log/redis
