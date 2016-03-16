![https://linuxserver.io](https://www.linuxserver.io/wp-content/uploads/2015/06/linuxserver_medium.png)

The [LinuxServer.io](https://linuxserver.io) team brings you another container release featuring easy user mapping and community support. Find us for support at:
* [forum.linuxserver.io](https://forum.linuxserver.io)
* [IRC](https://www.linuxserver.io/index.php/irc/) on freenode at `#linuxserver.io`
* [Podcast](https://www.linuxserver.io/index.php/category/podcast/) covers everything to do with getting the most from your Linux Server plus a focus on all things Docker and containerisation!

# lsiodev/musicbrainz
![](https://raw.githubusercontent.com/linuxserver/beta-templates/master/lsiodev/img/musicbrainzgitlogo.jpg)

MusicBrainz is an open music encyclopedia that collects music metadata and makes it available to the public. [Musicbrainz](https://musicbrainz.org/)

## Usage

```
docker create --name=musicbrainz \
-v <path to config >:/config \
-v <path to data >:/data \
-e PGID=<gid> -e PUID=<uid> \
-e BRAINZCODE=<code from musicbrainz> \
-e TZ=<timezone> \
-p 5000:5000 \
lsiodev/musicbrainz
```

**Parameters**

* `-p 5000` - the port(s)
* `-v /config` - config files for musicbrainz
* `-v /data` - data files for musicbrainz
* `-e PGID` for GroupID - see below for explanation
* `-e PUID` for UserID - see below for explanation
* `-e BRAINZCODE` - to enter musicbrainz code. see below
* `-e TZ` - timezone eg Europe/London

It is based on phusion-baseimage with ssh removed, for shell access whilst the container is running do `docker exec -it musicbrainz /bin/bash`.

### User / Group Identifiers

Sometimes when using data volumes (`-v` flags) permissions issues can arise between the host OS and the container. We avoid this issue by allowing you to specify the user `PUID` and group `PGID`. Ensure the data volume directory on the host is owned by the same user you specify and it will "just work" ™.

In this instance `PUID=1001` and `PGID=1001`. To find yours use `id user` as below:

```
  $ id <dockeruser>
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```
      
## Setting up the application 

* You must register here to recieve a musicbrainz code to allow you to recieve database updates, it is free. [Get Code here](https://metabrainz.org/supporters/account-type). 
* The initial import and setup of the database can take quite a long time, dependant on your download speed etc, be patient and don't restart the container before it's complete.
* It appears there are issues with unraid and using /mnt/user/cache/appdata instead of /mnt/cache/appdata, use /mnt/cache/appdata.

## Logs and shell
* To monitor the logs of the container in realtime `docker logs -f musicbrainz`.
* Shell access whilst the container is running: `docker exec -it musicbrainz /bin/bash`


## Versions
+ **16.03.2016:** Bump to latest server release
+ **26.02.2016:** Bump to latest server release
+ **08.02.16:** Switch to PPA version for redis
+ **03.01.2016:** Remove d/l of sitemaps file, missing from last 2 db dumps, 
move fetch of db/dump higher up initialise routine to allow easier resume of broken downloads.
+ **15.12.2015:** Per latest musicbrainz blog, switched to production branch,
latest stable code is now production branch in place of master.
+ **10.12.2015:** Initial release date 


