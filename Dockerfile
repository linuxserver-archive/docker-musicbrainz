FROM linuxserver/baseimage

MAINTAINER Sparklyballs <sparklyballs@linuxserver.io>

ENV DATA_ROOT="/data" PG_MAJOR="9.4"

ENV PERL5LIB="/app/perl"

ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8" \
URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport" \
PGCONF="/config" \

BASE_APTLIST="nodejs postgresql-common" \

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

# Install Postgres-common and nodejs
RUN curl -sL https://deb.nodesource.com/setup | bash - && \
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
apt-get update -q && \
apt-get install $BASE_APTLIST -qy && \
npm -g install npm@latest-2 && \
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install remaining packages
RUN apt-get update -q && \
apt-get install $APTLIST -qy && \

# fetch musicbrainz from git
git clone --recursive git://github.com/metabrainz/musicbrainz-server.git /app/musicbrainz && \

# install cpan and node packages
mkdir -p $PERL5LIB && \
cd /app/musicbrainz && \

# git checkout version
git checkout v-2015-05-18-schema-change && \

# standard cpamn modules
cpanm --installdeps --notest . && \

# extra, checkout version specific cpanm modules.
cpanm --notest SARTAK/MooseX-Role-Parameterized-0.27.tar.gz \
Plack::Middleware::Debug::Base \
Catalyst::Plugin::Cache::HTTP \
Catalyst::Plugin::StackTrace \
Cache::Memcached::Fast \
JSON::Any Cache::Memory \
Digest::MD5::File \
Term::Size::Any \
LWP::Protocol::https \
Starlet \
Plack::Handler::Starlet \
Starlet::Server \
Server::Starter \
TURNSTEP/DBD-Pg-3.4.2.tar.gz && \

cd /app/musicbrainz && \
npm install && \
./node_modules/.bin/gulp && \

# compile musicbrainz postgres deps
cd /app/musicbrainz/postgresql-musicbrainz-unaccent && \
make && \
make install && \
cd /app/musicbrainz/postgresql-musicbrainz-collate && \
make && \
make install && \

# clean up
apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# add Custom files
ADD defaults/ /defaults/
ADD init/ /etc/my_init.d/
ADD services/ /etc/service/
RUN chmod -v +x /etc/service/*/run /etc/my_init.d/*.sh 

# volumes and ports
VOLUME /config /data
EXPOSE 5000

