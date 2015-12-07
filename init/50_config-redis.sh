#!/bin/bash
mkdir -p /data/redis /var/log/redis

[[ ! -f /config/redis.conf ]] && cp /etc/redis/redis.conf /config/redis.conf
chown -R abc:abc /config/redis.conf /data/redis /var/log/redis
