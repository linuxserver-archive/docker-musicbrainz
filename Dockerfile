FROM linuxserver/baseimage.nginx

MAINTAINER Sparklyballs <sparklyballs@linuxserver.io>

ENV DATA_ROOT="/data" PG_MAJOR="9.4" 

ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8" \
URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport" \
PERL5LIB="/app/perl" PGCONF="/config" \

APTLIST="build-essential cpanminus git-core libbz2-dev \
libdb-dev libexpat1-dev libicu-dev libjson-xs-perl \
liblocal-lib-perl libpq-dev libxml2-dev memcached \
nodejs npm postgresql-$PG_MAJOR postgresql-client-$PG_MAJOR \
postgresql-contrib-$PG_MAJOR postgresql-plperl-$PG_MAJOR \
postgresql-server-dev-$PG_MAJOR python-software-properties \
redis-server software-properties-common wget"

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV MBDATA $DATA_ROOT/import
ENV PGDATA $DATA_ROOT/dbase

# Set the locale
RUN locale-gen en_US.UTF-8

# install postgres common
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
apt-get update -q && \
apt-get install postgresql-common -qy && \
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \

# cleanup
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install packages
RUN apt-get update -q && \
apt-get install $APTLIST -qy && \
ln -s /usr/bin/nodejs /usr/bin/node && \

# cleanup
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# clone musicbrainz repo
RUN git clone --recursive git://github.com/metabrainz/musicbrainz-server.git /app/musicbrainz && \

# install cpan and node packages
mkdir -p $PERL5LIB && \
cd /app/musicbrainz && \
# standard cpamn modules
cpanm --installdeps --notest . && \
npm install && \
./node_modules/.bin/gulp && \

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
ADD defaults/ /defaults/
ADD init/ /etc/my_init.d/
ADD services/ /etc/service/
RUN chmod -v +x /etc/service/*/run /etc/my_init.d/*.sh /defaults/update-script.sh
 
# volumes and ports
VOLUME /config /data
EXPOSE 5000

