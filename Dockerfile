FROM linuxserver/baseimage

MAINTAINER Sparklyballs <sparklyballs@linuxserver.io>

ENV DATA_ROOT="/data" PG_MAJOR="9.5" 

ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8" \
URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport" \
PERL5LIB="/app/perl" PGCONF="/config" \

APTLIST="build-essential cpanminus git-core libbz2-dev \
libdb-dev libexpat1-dev libicu-dev libjson-xs-perl \
liblocal-lib-perl libpq-dev libxml2-dev memcached \
postgresql-$PG_MAJOR postgresql-client-$PG_MAJOR \
postgresql-contrib-$PG_MAJOR postgresql-plperl-$PG_MAJOR \
postgresql-server-dev-$PG_MAJOR python-software-properties \
redis-server software-properties-common wget"

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV MBDATA $DATA_ROOT/import
ENV PGDATA $DATA_ROOT/dbase

# Set the locale
RUN locale-gen en_US.UTF-8

# add prebuilds
ADD defaults/ /defaults/

# install postgres common
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
curl -sL https://deb.nodesource.com/setup_0.12 | bash - && \
apt-get install nodejs postgresql-common -qy && \
npm install -g npm@latest && \
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \

# cleanup
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install packages
RUN add-apt-repository ppa:chris-lea/redis-server && \
apt-get update -q && \
apt-get install $APTLIST -qy && \
# ln -s /usr/bin/nodejs /usr/bin/node && \

# cleanup
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# clone musicbrainz repo
RUN git clone -b production --recursive git://github.com/metabrainz/musicbrainz-server.git /app/musicbrainz && \
cp /defaults/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm && \

# install cpan and node packages
mkdir -p $PERL5LIB && \
cd /app/musicbrainz && \
# standard cpamn modules
cpanm --installdeps --notest . && \
npm install && \
./script/compile_resources.sh && \

# compile musicbrainz postgres deps
cd /app/musicbrainz/postgresql-musicbrainz-unaccent && \
make && \
make install && \
cd /app/musicbrainz/postgresql-musicbrainz-collate && \
make && \
make install && \

# cleanup
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*


# add Custom files
ADD init/ /etc/my_init.d/
ADD services/ /etc/service/
RUN chmod -v +x /etc/service/*/run /etc/my_init.d/*.sh /defaults/update-script.sh && \
 
# configure redis server
sed 's/^loglevel notice/loglevel warning/' -i /etc/redis/redis.conf && \
sed 's/^daemonize yes/daemonize no/' -i /etc/redis/redis.conf && \
sed 's/^bind 127.0.0.1/bind 0.0.0.0/' -i /etc/redis/redis.conf && \
sed 's/^logfile \/var\/log\/redis\/redis-server.log/logfile \"\"/' -i /etc/redis/redis.conf && \
sed -i 's#/var/lib/redis#/data/redis#g' /etc/redis/redis.conf

# volumes and ports
VOLUME /config /data
EXPOSE 5000

