FROM lsiobase/alpine
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# copy files required in build stage
COPY prebuilds/ /defaults/

# package versions
ARG BRAINZ_VER="schema-change-2016-q2"

# global environment settings
ENV BABEL_DISABLE_CACHE="1" \
HOME="/root" \
LANG="en_US.utf8" \
MAX_WORKERS="1" \
MBDATA="/data/import" \
PATH="/usr/lib/postgresql/$PG_MAJOR/bin:$PATH" \
PGCONF="/config" \
PGDATA="/data/dbase" \
URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport"

# install build packages
RUN \
 apk add --no-cache --virtual=build-dependencies \
	db-dev \
	expat-dev \
	g++ \
	gcc \
	icu-dev \
	libxml2-dev \
	make \
	perl-dev && \

# install runtime packages
 apk add --no-cache \
	bzip2 \
	curl \
	expat \
	git \
	icu-libs \
	libpq \
	nodejs \
	patch \
	perl \
	perl-crypt-rijndael \
	perl-dbd-pg \
	perl-db_file \
	perl-net-ssleay \
	postgresql \
	postgresql-contrib \
	postgresql-dev \
	procps \
	redis \
	tar \
	wget && \

# fetch musicbrainz and install perl and node packages
 mkdir -p \
	/app/musicbrainz && \
 curl -o \
 /tmp/musicbrainz.tar.gz -L \
	"https://github.com/metabrainz/musicbrainz-server/archive/${BRAINZ_VER}.tar.gz" && \
 tar xf \
 /tmp/musicbrainz.tar.gz -C \
	/app/musicbrainz --strip-components=1 && \
 if [ ! -e "/app/musicbrainz/cpanfile" ]; then \
	cat /app/musicbrainz/Makefile.PL | grep ^requires > /app/musicbrainz/cpanfile; \
	fi  && \
 sed -i '/![^#]/ s/\(^.*test_requires 'Coro';.*$\)/#\ \1/' /app/musicbrainz/cpanfile && \
 cp /defaults/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm && \
 cd /app/musicbrainz && \
 curl -L http://cpanmin.us | perl - App::cpanminus && \
 cpanm --installdeps --notest . && \
 cpanm --notest \
	Cache::Memcached::Fast \
	Cache::Memory \
	Catalyst::Plugin::Cache::HTTP \
	Catalyst::Plugin::StackTrace \
	DBD::Pg \
	Digest::MD5::File \
	Plack::Handler::Starlet \
	Plack::Middleware::Debug::Base \
	Server::Starter \
	Starlet \
	Starlet::Server \
	Term::Size::Any && \
 npm install && \
 ./script/compile_resources.sh && \

# compile musicbrainz postgresql addons
 git clone git://github.com/metabrainz/postgresql-musicbrainz-unaccent \
	/tmp/postgresql-musicbrainz-unaccent && \
 cd /tmp/postgresql-musicbrainz-unaccent && \
	make && \
	make install && \
 git clone git://github.com/metabrainz/postgresql-musicbrainz-collate.git \
	/tmp/postgresql-musicbrainz-collate && \
 cd /tmp/postgresql-musicbrainz-collate && \
	make && \
	make install && \

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/root/.cpanm \
	/root/.npm \
	/tmp/*

# add local files
COPY root/ /

# volumes and ports
VOLUME /config /data
EXPOSE 5000
