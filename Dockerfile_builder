FROM alpine:3.4
MAINTAINER sparklyballs

# environment variables
ENV \
TERM="xterm"

# install packages
RUN \
 apk add --no-cache  \
	bash \
	git \
	openjdk8 && \
 apk add --no-cache \
	--repository http://nl.alpinelinux.org/alpine/edge/community \
	maven

# clone sources
RUN \
 git clone \
	https://github.com/metabrainz/mmd-schema.git /usr/src/mmd-schema && \
 git clone \
	https://github.com/metabrainz/search-server.git /usr/src/search-server && \

# build java files
 cd  /usr/src/mmd-schema/brainz-mmd2-jaxb && \
 mvn install && \
 cd /usr/src/search-server && \
 mvn package && \

# copy java files to output folder
 mkdir -p \
	/package && \
 cp \
	/usr/src/search-server/servlet/target/searchserver.war \
	/usr/src/search-server/index/target/index-2.0-SNAPSHOT-jar-with-dependencies.jar \
	/package/

# Copy java files out to mounted directory
CMD ["cp", "-avr", "/package", "/mnt/"]
