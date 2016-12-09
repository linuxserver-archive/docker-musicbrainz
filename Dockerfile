FROM lsiobase/alpine
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# copy files required in build stage
COPY prebuilds/ /defaults/

# global environment settings
ENV BABEL_DISABLE_CACHE="1" HOME="/root" \
LANG="en_US.UTF-8" LANGUAGE="en_US:en" MAX_WORKERS="1" \
POSTGRES_LOGS_FIFO="/var/run/s6/postgres-logs-fifo" TERM="xterm" \
URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport"
ENV PGCONF="/config" PG_MAJOR="9.5" DATA_ROOT="/data"
ENV PATH="/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH"
ENV MBDATA="${DATA_ROOT}/import" PGDATA="${DATA_ROOT}/dbase"

# build environment settings
ARG PERL5LIB="/app/perl"

# install build packages
RUN \
 apk add --no-cache --virtual=build-dependencies \
	expat-dev \
	g++ \
	gcc \
	git \
	icu-dev \
	libpq \
	libxml2-dev \
	make \
	perl-dev && \

# install runtime packages
 apk add --no-cache \
	bzip2 \
	curl \
	db-dev \
	icu-libs \
	memcached \
	nodejs \
	patch \
	perl \
	perl-crypt-rijndael \
	perl-net-ssleay \
	postgresql \
	postgresql-contrib \
	postgresql-dev \
	redis \
	tar \
	wget && \

# install cpanm
 curl -L http://cpanmin.us | perl - App::cpanminus && \

# fetch musicbrainz and install perl and node packages
 mkdir -p \
	/app/musicbrainz && \
 curl -o \
 /tmp/musicbrainz.tar.gz -L \
	https://github.com/metabrainz/musicbrainz-server/archive/production.tar.gz && \
 tar xf \
 /tmp/musicbrainz.tar.gz -C \
	/app/musicbrainz --strip-components=1 && \
 cp /defaults/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm && \
 cd /app/musicbrainz && \
 cpanm --installdeps --notest . && \
 cpanm --notest Starlet && \
 cpanm --notest Plack::Middleware::Debug::Base && \
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

# cleanup
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
