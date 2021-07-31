# OpenSRF Docker
This is a small experiment in running OpenSRF on Docker.  Has not been built out to support Evergreen.

It has minimal use apart from testing OpenSRF scenarios.

I have attempted to split opensrf across multiple containers to take advantage of its distributed natue.

It also uses `docker-compose` to create a 'public' and 'private' docker networks with the following containers:

- ejbbard container:
    - on `public` network, available on hostname `public.ejabberd`
    - on `private` network, available on hostname `private.ejabberd` 

- router container:
    - connected to both networks
    - runs both private and public routers

- app1-3 etc:
    - each one is a separate container
    - these should be configured in both opensrf.xml as well as docker-compose.yml

## Requirements
docker, docker-compose

## How to run 
```
docker-compose up
```

You will have a set of containers something like this:
```
NAME                        COMMAND                  SERVICE             STATUS              PORTS
opensrf-docker-app1-1       "/openils/bin/wrappe…"   app1                running
opensrf-docker-app2-1       "/openils/bin/wrappe…"   app2                running
opensrf-docker-app3-1       "/openils/bin/wrappe…"   app3                running
opensrf-docker-ejabberd-1   "/home/ejabberd/bin/…"   ejabberd            running             0.0.0.0:5222->5222/tcp
opensrf-docker-router-1     "/openils/bin/wrappe…"   router              running

```
To access a srfsh session on app1 you can run something like this:
```
docker-compose run --user opensrf app1 /openils/bin/srfsh  
```
Make sure to type "exit" to end the srfsh session -- using CTRL-C may leave the container running.

To get a bash shell on app1 you can run this:
```docker-compose exec --user opensrf app1 /bin/bash```

## What each container does

### Ejabberd

Ejabberd runs in its own container using the official `ejabberd/ecs` container from DockerHub.  It uses the ejabberd.yml in the ejabberd directory which has been pre-configured for OpenSRF.  

The private domain (hostname `private.ejabberd`) and public domain (hostname `public.ejabberd`) are each on their own docker network, named private and public respectively.  This is all configured in the `docker-compose.yml`.  Any containers that need to talk to ejabberd on that domain must also be mapped to the network in `docker-compose.yml`

The ejabberd container attemps to register the domain users after ejabberd starts.  

Sometimes the OpenSRF containers fail to start because the ejabberd users have not yet been registered.  You can try restarting the OpenSRF containers by running `docker-compose restart app1-1 app1-2 app1-3`

Note mod_fail2ban on ejabberd caused some issues so it is disabled.

### OpenSRF Containers

Each opensrf app container uses bind-mounted config files in the local `/opensrf` dir, so changing these files will change the config for *all* containers -- although each container must be restarted for them to take effect.  

Each container corresponds to a host entry in `opensrf.xml`, so you must make sure the `docker-compose.yml` and `opensrf.xml` are in sync.

The OpenSRF containers use a script -- `wrapper.sh` found in the opensrf directory and bind-mounted to the containers, which will scan for processes matching the pidfiles in `/openils/var/run` and fail if the process is not running.  This is a bit hack-ish and won't obviously take into account every situation, for example if the process stops and pidfile is cleaned up, but for the most part, restarting the container should fix any issue.

Normally Docker apps run in the foregound without forking and print logs to STDOUT.  However, OpenSRF wasn't really designed this way.  OpenSRF Router forks into the background.  OpenSRF Perl apps can be run in the foregound, but you can only run a single OpenSRF perl app in the foreground at a time.

The script `wrapper.sh` essentially wraps `osrf_control` so you can pass in the same arguments in the `command` section of `docker-compose.yml`, which allows you to control where OpenSRF router is run.

### Router

OpenSRF Router runs in its own container.  It would probably be possible to split out separate router containers for the public/private routers by adjusting the wrapper script.


## More Notes

Scaling up an app container using `docker-compose --scale` seems to work well which is neat.  

If things break, usually `docker-compose restart` will fix it

