FROM ubuntu:14.04
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# build environment settings
ARG PERL5LIB="/app/perl"
ARG DEBIAN_FRONTEND="noninteractive"

# set version for s6 overlay
ARG OVERLAY_VERSION="v1.18.1.5"

# global environment settings
ENV BABEL_DISABLE_CACHE="1" HOME="/root" \
LANG="en_US.UTF-8" LANGUAGE="en_US:en" MAX_WORKERS="1" \
POSTGRES_LOGS_FIFO="/var/run/s6/postgres-logs-fifo" TERM="xterm" \
URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport"
ENV PGCONF="/config" PG_MAJOR="9.5" DATA_ROOT="/data"
ENV PATH="/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH"
ENV MBDATA="${DATA_ROOT}/import" PGDATA="${DATA_ROOT}/dbase"

# copy files required in build stage
COPY prebuilds/ /defaults/

# add abc user and set locale
RUN \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 locale-gen en_US.UTF-8

# add postgresql repository and configure postgresql-common to not create cluster.
RUN \
 apt-key adv --keyserver keyserver.ubuntu.com \
	--recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
 echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > \
	/etc/apt/sources.list.d/pgdg.list && \
 apt-get update -q && \
 apt-get install -y \
	postgresql-common && \
 sed -ri \
	's/#(create_main_cluster) .*$/\1 = false/' \
	/etc/postgresql-common/createcluster.conf && \

# cleanup
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# install dependencies
RUN \
 apt-get update && \
 apt-get install -y \
	cpanminus \
	cron \
	curl \
	g++ \
	gcc \
	git-core \
	libdb-dev \
	libexpat1-dev \
	libicu-dev \
	libpq-dev \
	libxml2-dev \
	make \
	memcached \
	patch \
	postgresql-contrib-"${PG_MAJOR}" \
	postgresql-"${PG_MAJOR}" \
	postgresql-server-dev-"${PG_MAJOR}" \
	redis-server \
	wget && \

# install nodejs and npm
 curl -sL \
	https://deb.nodesource.com/setup_4.x | bash - && \
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
 npm install && \
 ./script/compile_resources.sh && \

# compile musicbrainz postgresql addons
 cd /app/musicbrainz/postgresql-musicbrainz-unaccent && \
	make && \
	make install && \
 cd /app/musicbrainz/postgresql-musicbrainz-collate && \
	make && \
	make install && \

# uninstall build-dependencies
 apt-get purge --remove -y \
	binutils \
	g++ \
	gcc \
	git-core \
	libexpat1-dev \
	libicu-dev \
	libpq-dev \
	libxml2-dev \
	make && \
 apt-get autoremove -y && \
 apt-get autoclean -y && \

# install runtime dependencies
 apt-get update && \
 apt-get install -y \
	libicu52 && \

# add s6 overlay
# add s6 overlay
 curl -o \
 /tmp/s6-overlay.tar.gz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
 tar xvfz /tmp/s6-overlay.tar.gz -C / && \

# cleanup
 apt-get clean && \
 npm cache clean && \
 rm -rf \
	/root/.cpanm \
	/root/.npm \
	/tmp/* \
	/var/lib/apt/lists/*

# add local files
COPY root/ /

# configure cron
RUN \
 chmod 600 /etc/crontab && \
 chmod +x /defaults/update-script.sh && \
 rm -f \
	/etc/cron.daily/dpkg \
	/etc/cron.daily/password \
	/etc/cron.daily/standard \
	/etc/cron.daily/upstart \
	/etc/cron.weekly/fstrim

ENTRYPOINT ["/init"]

# volumes and ports
VOLUME /config /data
EXPOSE 5000
