[![linuxserver.io](https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/linuxserver_medium.png)](https://linuxserver.io)

The [LinuxServer.io](https://linuxserver.io) team brings you another container release featuring :-

 * regular and timely application updates
 * easy user mappings (PGID, PUID)
 * custom base image with s6 overlay
 * weekly base OS updates with common layers across the entire LinuxServer.io ecosystem to minimise space usage, down time and bandwidth
 * regular security updates

Find us at:
* [Discord](https://discord.gg/YWrKVTn) - realtime support / chat with the community and the team.
* [IRC](https://irc.linuxserver.io) - on freenode at `#linuxserver.io`. Our primary support channel is Discord.
* [Blog](https://blog.linuxserver.io) - all the things you can do with our containers including How-To guides, opinions and much more!
* [Podcast](https://anchor.fm/linuxserverio) - on hiatus. Coming back soon (late 2018).

# [linuxserver/musicbrainz](https://github.com/linuxserver/docker-musicbrainz)
[![](https://img.shields.io/discord/354974912613449730.svg?logo=discord&label=LSIO%20Discord&style=flat-square)](https://discord.gg/YWrKVTn)
[![](https://images.microbadger.com/badges/version/linuxserver/musicbrainz.svg)](https://microbadger.com/images/linuxserver/musicbrainz "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/linuxserver/musicbrainz.svg)](https://microbadger.com/images/linuxserver/musicbrainz "Get your own version badge on microbadger.com")
![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/musicbrainz.svg)
![Docker Stars](https://img.shields.io/docker/stars/linuxserver/musicbrainz.svg)
[![Build Status](https://ci.linuxserver.io/buildStatus/icon?job=Docker-Pipeline-Builders/docker-musicbrainz/master)](https://ci.linuxserver.io/job/Docker-Pipeline-Builders/job/docker-musicbrainz/job/master/)
[![](https://lsio-ci.ams3.digitaloceanspaces.com/linuxserver/musicbrainz/latest/badge.svg)](https://lsio-ci.ams3.digitaloceanspaces.com/linuxserver/musicbrainz/latest/index.html)

[Musicbrainz](https://musicbrainz.org/) is an open music encyclopedia that collects music metadata and makes it available to the public.

[![musicbrainz](https://raw.githubusercontent.com/linuxserver/beta-templates/master/lsiodev/img/musicbrainzgitlogo.jpg)](https://musicbrainz.org/)

## Supported Architectures

Our images support multiple architectures such as `x86-64`, `arm64` and `armhf`. We utilise the docker manifest for multi-platform awareness. More information is available from docker [here](https://github.com/docker/distribution/blob/master/docs/spec/manifest-v2-2.md#manifest-list) and our announcement [here](https://blog.linuxserver.io/2019/02/21/the-lsio-pipeline-project/). 

Simply pulling `linuxserver/musicbrainz` should retrieve the correct image for your arch, but you can also pull specific arch images via tags.

The architectures supported by this image are:

| Architecture | Tag |
| :----: | --- |
| x86-64 | amd64-latest |
| arm64 | arm64v8-latest |
| armhf | arm32v6-latest |


## Usage

Here are some example snippets to help you get started creating a container.

### docker

```
docker create \
  --name=musicbrainz \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -e BRAINZCODE=<code from musicbrainz> \
  -e WEBADDRESS=<ip of host> \
  -e NPROC=<parameter> `#optional` \
  -p 5000:5000 \
  -v </path/to/appdata/config>:/config \
  -v </path/to/appdata/config>:/data \
  --restart unless-stopped \
  linuxserver/musicbrainz
```


### docker-compose

Compatible with docker-compose v2 schemas.

```
---
version: "2"
services:
  musicbrainz:
    image: linuxserver/musicbrainz
    container_name: musicbrainz
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - BRAINZCODE=<code from musicbrainz>
      - WEBADDRESS=<ip of host>
      - NPROC=<parameter> #optional
    volumes:
      - </path/to/appdata/config>:/config
      - </path/to/appdata/config>:/data
    ports:
      - 5000:5000
    restart: unless-stopped
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 5000` | WebUI |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Europe/London` | Specify a timezone to use EG Europe/London |
| `-e BRAINZCODE=<code from musicbrainz>` | To enter musicbrainz code. see Setting up the application |
| `-e WEBADDRESS=<ip of host>` | To set ip for host to allow css to render properly, DO NOT ENTER PORT NUMBER. |
| `-e NPROC=<parameter>` | To set number of proceses, defaults to 5 if unset. |
| `-v /config` | Config files for musicbrainz. |
| `-v /data` | Data files for musicbrainz. |

## User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id user` as below:

```
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```


&nbsp;
## Application Setup

+ For schema 24 updates you should pull the latest image, clear all files and folders in /config and /data and reinitiate the database import by (re)starting the docker.

+ **If you did not set WEBADDRESS env variable, then AFTER iniatilisation is complete you will need to edit the line `sub WEB_SERVER { "localhost:5000" }` in file /config/DBDefs.pm changing localhost to the ip of your host, this is to allow css to display properly**

* You must register here to recieve a musicbrainz code to allow you to recieve database updates, it is free. [Get Code here](https://metabrainz.org/supporters/account-type).
* The initial import and setup of the database can take quite a long time, dependant on your download speed etc, be patient and don't restart the container before it's complete.
* It appears there are issues with unraid and using /mnt/user/cache/appdata instead of /mnt/cache/appdata, use /mnt/cache/appdata.



## Support Info

* Shell access whilst the container is running: `docker exec -it musicbrainz /bin/bash`
* To monitor the logs of the container in realtime: `docker logs -f musicbrainz`
* container version number 
  * `docker inspect -f '{{ index .Config.Labels "build_version" }}' musicbrainz`
* image version number
  * `docker inspect -f '{{ index .Config.Labels "build_version" }}' linuxserver/musicbrainz`

## Updating Info

Most of our images are static, versioned, and require an image update and container recreation to update the app inside. With some exceptions (ie. nextcloud, plex), we do not recommend or support updating apps inside the container. Please consult the [Application Setup](#application-setup) section above to see if it is recommended for the image.  
  
Below are the instructions for updating containers:  
  
### Via Docker Run/Create
* Update the image: `docker pull linuxserver/musicbrainz`
* Stop the running container: `docker stop musicbrainz`
* Delete the container: `docker rm musicbrainz`
* Recreate a new container with the same docker create parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* Start the new container: `docker start musicbrainz`
* You can also remove the old dangling images: `docker image prune`

### Via Taisun auto-updater (especially useful if you don't remember the original parameters)
* Pull the latest image at its tag and replace it with the same env variables in one shot:
  ```
  docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock taisun/updater \
  --oneshot musicbrainz
  ```
* You can also remove the old dangling images: `docker image prune`

### Via Docker Compose
* Update all images: `docker-compose pull`
  * or update a single image: `docker-compose pull musicbrainz`
* Let compose update all containers as necessary: `docker-compose up -d`
  * or update a single container: `docker-compose up -d musicbrainz`
* You can also remove the old dangling images: `docker image prune`

## Versions

* **02.03.19:** - Revert to alpine 3.6 to avoid database migrations.
* **19.02.19:** - Multi Arch and add pipeline logic, rebase to Alpine 3.9
* **22.08.18:** - Bump server version 2018-08-14.
* **30.06.18:** - Bump server version 2018-06-30.
* **01.06.18:** - Bump server version 2018-05-30 , simplify sed and use yarn instead of npm.
* **14.05.18:** - Bump server version 2018-05-09.
* **26.04.18:** - Bump server version 2018-04-23.
* **09.02.18:** - Bump server version 2018-02-09.
* **24.01.18:** - Bump server version 2018-01-24.
* **10.01.18:** - Bump server version 2018-01-10.
* **31.11.17:** - Bump server version 2017-12-21.
* **30.11.17:** - Add NPROC variable  to allow number of processes to be set.
* **30.11.17:** - Fix linting recommendations.
* **30.11.17:** - Remove socket on startup if exists (thanks wtf911) [re](https://tickets.metabrainz.org/browse/MBS-9370).
* **24.11.17:** - Remove catalyst side bar on new installs.
* **31.10.17:** - Bump server version 2017-10-31.
* **20.09.17:** - Bump server version 2017-09-18.
* **06.09.17:** - Bump server version 2017-09-04.
* **19.07.17:** - Bump server version 2017-07-17.
* **21.06.17:** - Bump server version 2017-06-19.
* **26.05.17:** - Fix later build of postgres using /run instead of /var/run.
* **26.05.17:** - Rebase to alpine 3.6.
* **15.05.17:** - Schema 24 update, recommend full rebuild with new config.
* **15.04.17:** - Bump server version 2017-04-10.
* **04.04.17:** - Bump server version 2017-03-27.
* **15.03.17:** - Bump server version 2017-03-13.
* **04.03.17:** - Bump server version and use nginx to serve web pages.
* **06.02.17:** - Rebase to alpine 3.5.
* **16.12.16:** - Rebase to alpine linux, entailing almost complete rewrite.
* **14.10.16:** - Add version layer information.
* **30.09.16:** - Fix umask.
* **10.09.16:** - Add layer badges to README.
* **28.08.16:** - Add badges to README, move to main repository.
* **20.07.16:** - Restructure of docker file for clarity, add maxworkers variable in conjunction with starlet, for parallel requests in multi-core setups, thanks to user baoshan.
* **03.06.16:** - Complete rewrite due to schema change. Rebased back to 14.04 direct Using S6 overaly.
* **21.03.16:** - Bump to latest server release.
* **16.03.16:** - Bump to latest server release.
* **26.02.16:** - Bump to latest server release.
* **08.02.16:** - Switch to PPA version for redis.
* **03.01.16:** - Remove d/l of sitemaps file, missing from last 2 db dumps, move fetch of db/dump higher up initialise routine to allow easier resume of broken downloads.
* **15.12.15:** - Per latest musicbrainz blog, switched to production branch,latest stable code is now production branch in place of master.
* **10.12.15:** - Initial release date.
