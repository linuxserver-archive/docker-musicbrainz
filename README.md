[linuxserverurl]: https://linuxserver.io
[forumurl]: https://forum.linuxserver.io
[ircurl]: https://www.linuxserver.io/irc/
[podcasturl]: https://www.linuxserver.io/podcast/
[appurl]: https://musicbrainz.org/
[hub]: https://hub.docker.com/r/linuxserver/musicbrainz/

[![linuxserver.io](https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/linuxserver_medium.png)][linuxserverurl]

The [LinuxServer.io][linuxserverurl] team brings you another container release featuring easy user mapping and community support. Find us for support at:
* [forum.linuxserver.io][forumurl]
* [IRC][ircurl] on freenode at `#linuxserver.io`
* [Podcast][podcasturl] covers everything to do with getting the most from your Linux Server plus a focus on all things Docker and containerisation!

# linuxserver/musicbrainz
[![](https://images.microbadger.com/badges/version/linuxserver/musicbrainz.svg)](https://microbadger.com/images/linuxserver/musicbrainz "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/linuxserver/musicbrainz.svg)](http://microbadger.com/images/linuxserver/musicbrainz "Get your own image badge on microbadger.com")[![Docker Pulls](https://img.shields.io/docker/pulls/linuxserver/musicbrainz.svg)][hub][![Docker Stars](https://img.shields.io/docker/stars/linuxserver/musicbrainz.svg)][hub][![Build Status](http://jenkins.linuxserver.io:8080/buildStatus/icon?job=Dockers/LinuxServer.io/linuxserver-musicbrainz)](http://jenkins.linuxserver.io:8080/job/Dockers/job/LinuxServer.io/job/linuxserver-musicbrainz/)

[MusicBrainz][appurl] is an open music encyclopedia that collects music metadata and makes it available to the public.

[![musicbrainz](https://raw.githubusercontent.com/linuxserver/beta-templates/master/lsiodev/img/musicbrainzgitlogo.jpg)][appurl]

## Usage

```
docker create --name=musicbrainz \
-v <path to config >:/config \
-v <path to data >:/data \
-e PGID=<gid> -e PUID=<uid> \
-e BRAINZCODE=<code from musicbrainz> \
-e TZ=<timezone> \
-e WEBADDRESS=<ip of host> \
-p 5000:5000 \
linuxserver/musicbrainz
```

## Parameters

`The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. 
For example with a port -p external:internal - what this shows is the port mapping from internal to external of the container.
So -p 8080:80 would expose port 80 from inside the container to be accessible from the host's IP on port 8080
http://192.168.x.x:8080 would show you what's running INSIDE the container on port 80.`


* `-p 5000` - the port(s)
* `-v /config` - config files for musicbrainz
* `-v /data` - data files for musicbrainz
* `-e PGID` for GroupID - see below for explanation
* `-e PUID` for UserID - see below for explanation
* `-e BRAINZCODE` - to enter musicbrainz code. see below
* `-e WEBADDRESS` - to set ip for host to allow css to render properly, DO NOT ENTER PORT NUMBER.
* `-e TZ` - timezone eg Europe/London

It is based on alpine linux with S6 overlay, for shell access whilst the container is running do `docker exec -it musicbrainz /bin/bash`.

### User / Group Identifiers

Sometimes when using data volumes (`-v` flags) permissions issues can arise between the host OS and the container. We avoid this issue by allowing you to specify the user `PUID` and group `PGID`. Ensure the data volume directory on the host is owned by the same user you specify and it will "just work" ™.

In this instance `PUID=1001` and `PGID=1001`. To find yours use `id user` as below:

```
  $ id <dockeruser>
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```
      
## Setting up the application 
+ For schema 24 updates you should pull the latest image, clear all files and folders in /config and /data and reinitiate the database import by (re)starting the docker.

+ **If you did not set WEBADDRESS env variable, then AFTER iniatilisation is complete you will need to edit the line `sub WEB_SERVER { "localhost:5000" }` in file /config/DBDefs.pm changing localhost to the ip of your host, this is to allow css to display properly**

* You must register here to recieve a musicbrainz code to allow you to recieve database updates, it is free. [Get Code here](https://metabrainz.org/supporters/account-type). 
* The initial import and setup of the database can take quite a long time, dependant on your download speed etc, be patient and don't restart the container before it's complete.
* It appears there are issues with unraid and using /mnt/user/cache/appdata instead of /mnt/cache/appdata, use /mnt/cache/appdata.

## Info
* To monitor the logs of the container in realtime `docker logs -f musicbrainz`.
* Shell access whilst the container is running: `docker exec -it musicbrainz /bin/bash`

* container version number 

`docker inspect -f '{{ index .Config.Labels "build_version" }}' musicbrainz`

* image version number

`docker inspect -f '{{ index .Config.Labels "build_version" }}' linuxserver/musicbrainz`

## Versions

+ **26.05.17:** Rebase to alpine 3.6.
+ **15.05.17:** Schema 24 update, recommend full rebuild with new config.
+ **15.04.17:** Bump server version 2017-04-10.
+ **04.04.17:** Bump server version 2017-03-27.
+ **15.03.17:** Bump server version 2017-03-13.
+ **04.03.17:** Bump server version and use nginx to serve web pages.
+ **06.02.17:** Rebase to alpine 3.5.
+ **16.12.16:** Rebase to alpine linux, entailing almost complete rewrite.
+ **14.10.16:** Add version layer information.
+ **30.09.16:** Fix umask.
+ **10.09.16:** Add layer badges to README.
+ **28.08.16:** Add badges to README, move to main repository.
+ **20.07.16:** Restructure of docker file for clarity, add maxworkers variable in conjunction with starlet,
for parallel requests in multi-core setups, thanks to user baoshan. 
+ **03.06.16:** Complete rewrite due to schema change. Rebased back to 14.04 direct Using S6 overaly.
+ **21.03.16:** Bump to latest server release
+ **16.03.16:** Bump to latest server release
+ **26.02.16:** Bump to latest server release
+ **08.02.16:** Switch to PPA version for redis
+ **03.01.16:** Remove d/l of sitemaps file, missing from last 2 db dumps, 
move fetch of db/dump higher up initialise routine to allow easier resume of broken downloads.
+ **15.12.15:** Per latest musicbrainz blog, switched to production branch,
latest stable code is now production branch in place of master.
+ **10.12.15:** Initial release date
