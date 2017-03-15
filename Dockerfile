FROM lsiobase/alpine:3.5
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# copy files required in build stage
COPY prebuilds/ /defaults/

# package versions
ARG BRAINZ_VER="v-2017-03-13"

# global environment settings
ENV BABEL_DISABLE_CACHE="1" \
HOME="/root" \
LANG="en_US.utf8" \
MAX_WORKERS="1" \
MBDATA="/data/import" \
PGCONF="/config" \
PGDATA="/data/dbase" \
UPDATE_SLAVE_LOGDIR="/config/log/musicbrainz" \
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
	db \
	expat \
	git \
	icu-libs \
	nginx \
	nodejs \
	patch \
	logrotate \
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
 sed -i 's#$MB_SERVER_ROOT/#$UPDATE_SLAVE_LOGDIR/#g' /app/musicbrainz/admin/cron/slave.sh && \
 cp /defaults/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm && \
 cd /app/musicbrainz && \
 curl -L http://cpanmin.us | perl - App::cpanminus && \
 cpanm --installdeps --notest . && \
 cpanm --notest \
	Cache::Memcached::Fast \
	Cache::Memory \
	Catalyst::Plugin::Cache::HTTP \
	Catalyst::Plugin::StackTrace \
	Digest::MD5::File \
	FCGI \
	FCGI::ProcManager \
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

# configure nginx
 echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> \
	/etc/nginx/fastcgi_params && \
 rm -f /etc/nginx/conf.d/default.conf && \

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
