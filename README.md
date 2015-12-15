![http://linuxserver.io](http://www.linuxserver.io/wp-content/uploads/2015/06/linuxserver_medium.png)

The [LinuxServer.io](https://www.linuxserver.io/) team brings you another quality container release featuring easy user mapping and community support. Be sure to checkout our [forums](https://forum.linuxserver.io/index.php) or for real-time support our [IRC](https://www.linuxserver.io/index.php/irc/) on freenode at `#linuxserver.io`.

# lsiodev/musicbrainz

MusicBrainz is an open music encyclopedia that collects music metadata and makes it available to the public. [Musicbrainz](https://musicbrainz.org/)

## Usage

```
docker create --name=musicbrainz -v <path to config >:/config -v <path to data >:/data -e PGID=<gid> -e PUID=<uid> -e BRAINZCODE=<code from musicbrainz> -e TZ=<timezone> -p 5000:5000 lsiodev/musicbrainz
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

**TL;DR** - The `PGID` and `PUID` values set the user / group you'd like your container to 'run as' to the host OS. This can be a user you've created or even root (not recommended).

Part of what makes our containers work so well is by allowing you to specify your own `PUID` and `PGID`. This avoids nasty permissions errors with relation to data volumes (`-v` flags). When an application is installed on the host OS it is normally added to the common group called users, Docker apps due to the nature of the technology can't be added to this group. So we added this feature to let you easily choose when running your containers.

## Setting up the application 

* You must register here to recieve a musicbrainz code to allow you to recieve database updates, it is free. [Get Code here](https://metabrainz.org/supporters/account-type). 
* The initial import and setup of the database can take quite a long time, dependant on your download speed etc, be patient and don't restart the container before it's complete.


## Logs
* To monitor the logs of the container in realtime `docker logs -f musicbrainz`.



## Versions
+ **15.12.2015:** Per latest musicbrainz blog, switched to production branch,
latest stable code is now production branch in place of master.
+ **10.12.2015:** Initial release date 


