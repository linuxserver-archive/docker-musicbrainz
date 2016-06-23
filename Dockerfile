FROM ubuntu:14.04
MAINTAINER sparklyballs

# build environment settings
ARG PERL5LIB="/app/perl"
ARG DEBIAN_FRONTEND="noninteractive"

# global environment settings
ENV HOME="/root"
ENV TERM="xterm"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV PGCONF="/config"
ENV DATA_ROOT="/data"
ENV PG_MAJOR="9.5"
ENV PATH /usr/lib/postgresql/"${PG_MAJOR}"/bin:$PATH
ENV MBDATA="${DATA_ROOT}"/import
ENV PGDATA="${DATA_ROOT}"/dbase
ENV URL_ROOT="ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport"
ENV POSTGRES_LOGS_FIFO="/var/run/s6/postgres-logs-fifo"

# copy files required in build stage
COPY prebuilds/ /defaults/

# add abc user and set locale
RUN \
 useradd -u 911 -U -d /config -s /bin/false abc && \
	usermod -G users abc && \
	locale-gen en_US.UTF-8

# add postgresql repository and configure postgresql-common to not create cluster.
RUN \
 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
 echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
 apt-get update -q && \
 apt-get install -y \
	postgresql-common && \
	sed -ri 's/#(create_main_cluster) .*$/\1 = false/' \
	/etc/postgresql-common/createcluster.conf && \

# cleanup
 apt-get clean && \
 rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install dependencies
RUN \
 apt-get update -q && \
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
 curl -sL https://deb.nodesource.com/setup_0.12 | bash - && \
 apt-get install -y \
	nodejs && \
 	npm install -g npm@latest && \

# clone musicbrainz and install perl and node packages
 git clone -b production --recursive git://github.com/metabrainz/musicbrainz-server.git /app/musicbrainz && \
 cp /defaults/DBDefs.pm /app/musicbrainz/lib/DBDefs.pm && \
 cd /app/musicbrainz && \
	cpanm MLEHMANN/Coro-6.49.tar.gz && \
	cpanm --installdeps --notest . && \
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
	libexpat1 \
	libicu52 \
	libpq5 \
	libxml2 && \

# add s6 overlay
 wget -O /tmp/s6.tar.gz \
	https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz && \
	tar xvf /tmp/s6.tar.gz -C / && \

# cleanup
 apt-get clean && \
 npm cache clean && \
 rm -rfv /var/lib/apt/lists/* /root/.cpanm /root/.npm /tmp/*

# add local files
COPY root/ /

# configure cron
RUN \
 chmod 600 /etc/crontab && \
 chmod +x /defaults/update-script.sh && \
 rm -fv \
	/etc/cron.daily/standard \
	/etc/cron.daily/upstart \
	/etc/cron.daily/dpkg \
	/etc/cron.daily/password \
	/etc/cron.weekly/fstrim

ENTRYPOINT ["/init"]

# volumes and ports
VOLUME /config /data
EXPOSE 5000
