FROM lsiobase/alpine
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# copy files required in build stage
COPY prebuilds/ /defaults/

# package versions
ARG BRAINZ_VER="production"
ENV PG_MAJOR="9.6" \
PG_VERSION="9.6.1"

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

# install postgres build packages
RUN \
 apk add --no-cache --virtual=postgres_build-dependencies \
	bison \
	curl \
	flex \
	gcc \
	libc-dev \
	libedit-dev \
	libxml2-dev \
	libxslt-dev \
	make \
	openssl-dev \
	perl \
	tar \
	util-linux-dev \
	zlib-dev && \

# compile postgres
 mkdir -p \
	/tmp/postgres-src && \
 curl -o \
 /postgres.tar.bz2 -L \
	"https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2" && \
 tar xf \
 /postgres.tar.bz2 -C \
	/tmp/postgres-src --strip-components=1 && \
 cd /tmp/postgres-src && \
 ./configure \
	--disable-rpath \
	--enable-integer-datetimes \
	--enable-tap-tests \
	--enable-thread-safety \
	--prefix=/usr/local \
	--with-gnu-ld \
	--with-libxml \
	--with-libxslt \
	--with-openssl \
	--with-pgport=5432 \
	--with-system-tzdata=/usr/share/zoneinfo \
	--with-uuid=e2fs && \
 make world && \
 make install-world && \
 make -C contrib install && \
 RUN_PACKAGES="$( \
	scanelf --needed --nobanner --recursive /usr/local \
	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
	| sort -u \
	| xargs -r apk info --installed \
	| sort -u \
	)" && \
 apk add --no-cache \
	${RUN_PACKAGES} && \
 sed -ri \
	"s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" \
	/usr/local/share/postgresql/postgresql.conf.sample && \
# cleanup postgresql build
 apk del --purge \
	postgres_build-dependencies && \
 rm -rf \
	/tmp/*

# MUSICBRAINZ INSTALL STARTS HERE

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
	nodejs \
	patch \
	libpq \
	perl \
	perl-crypt-rijndael \
	perl-dbd-pg \
	perl-net-ssleay \
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
 cp /defaults/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm && \
 cd /app/musicbrainz && \
 curl -L http://cpanmin.us | perl - App::cpanminus && \
 cpanm --installdeps --notest . && \
 cpanm --notest \
	Cache::Memcached::Fast \
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
