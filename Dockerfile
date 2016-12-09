FROM lsiobase/xenial
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# global environment settings
ENV BABEL_DISABLE_CACHE="1" HOME="/root" \
LANG="en_US.UTF-8" LANGUAGE="en_US:en" MAX_WORKERS="1" \
POSTGRES_LOGS_FIFO="/var/run/s6/postgres-logs-fifo" TERM="xterm" \
URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport"
ENV PGCONF="/config" PG_MAJOR="9.5" DATA_ROOT="/data"
ENV PATH="/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH"
ENV MBDATA="${DATA_ROOT}/import" PGDATA="${DATA_ROOT}/dbase"

# build environment settings
ARG PERL5LIB="/app/perl"
ARG DEBIAN_FRONTEND="noninteractive"
ARG BUILD_PACKAGES="\
	binutils \
	g++ \
	gcc \
	git-core \
	libexpat1-dev \
	libicu-dev \
	libpq-dev \
	libxml2-dev \
	make"
ARG RUNTIME_PACKAGES="\
	bzip2 \
	cpanminus \
	cron \
	curl \
	libdb-dev \
	libicu55 \
	memcached \
	patch \
	postgresql-contrib-"${PG_MAJOR}" \
	postgresql-"${PG_MAJOR}" \
	postgresql-server-dev-"${PG_MAJOR}" \
	redis-server \
	wget"

# copy files required in build stage
COPY prebuilds/ /defaults/

# set locale
RUN \
 locale-gen en_US.UTF-8 && \

# install packages
 apt-key adv --keyserver keyserver.ubuntu.com \
	--recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
 echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > \
	/etc/apt/sources.list.d/pgdg.list && \
 apt-get update && \
 apt-get install -y \
	postgresql-common && \
	sed -ri 's/#(create_main_cluster) .*$/\1 = false/' \
	/etc/postgresql-common/createcluster.conf && \
 ldconfig && \
 apt-get install -y \
	${BUILD_PACKAGES} \
	${RUNTIME_PACKAGES} && \

# install nodejs and npm
 curl -sL \
	https://deb.nodesource.com/setup_7.x | bash - && \
 apt-get install -y \
	nodejs && \
 npm install -g npm@latest && \

# clone musicbrainz, check out latest production release and install perl and node packages
 git clone --recursive \
	git://github.com/metabrainz/musicbrainz-server.git \
	/app/musicbrainz && \
 git -C /app/musicbrainz \
	checkout $(git -C /app/musicbrainz describe --tags --candidates=1 --abbrev=0) && \
 cp /defaults/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm && \
 cd /app/musicbrainz && \
 cpanm --installdeps --notest . && \
 cpanm --notest Starlet && \
 cpanm --notest Plack::Middleware::Debug::Base && \
 npm install && \
 ./script/compile_resources.sh && \

# compile musicbrainz postgresql addons
 cd /app/musicbrainz/postgresql-musicbrainz-unaccent && \
	make && \
	make install && \
 cd /app/musicbrainz/postgresql-musicbrainz-collate && \
	make && \
	make install && \

# configure cron
 chmod 600 /etc/crontab && \
 rm -f \
	/etc/cron.daily/dpkg \
	/etc/cron.daily/password \
	/etc/cron.daily/standard \
	/etc/cron.daily/upstart \
	/etc/cron.weekly/fstrim && \

# cleanup
 apt-get purge -y --auto-remove \
	${BUILD_PACKAGES} && \
 npm cache clean && \
 rm -rf \
	/root/.cpanm \
	/root/.npm \
	/tmp/* \
	/var/lib/apt/lists/*

# add local files
COPY root/ /
RUN \
	chmod +x /defaults/update-script.sh

# volumes and ports
VOLUME /config /data
EXPOSE 5000
