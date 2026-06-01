# calma-devops
Setup for Services

## Start service
docker compose up -d

## PgAdmin
https://admin.spinnaker.sysdesign.no:8080

## PostgREST

## Deploy - Pull from vm
Get keys
Add the folowing to ./ssh/config
``` Host github.com-calma
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_calma
    IdentitiesOnly yes
```
Pull:
``git clone git@github.com-calma:mariusu/calma-devops.git /opt/minapp``

## Setup PowerSync
https://docs.powersync.com/configuration/source-db/setup#supabase
### Setup publication in Postgres

For dev environments, its ok to run:
```
CREATE PUBLICATION powersync FOR ALL TABLES;
```
For production, add tables maually
```
ALTER PUBLICATION powersync ADD TABLE todos_test;
```

## Docker compose
Data is saved here: ``/var/lib/docker/volumes``

### Docker compose usage
Start/update all services: ``docker compose up``  
Stop all services: ``docker compose down``  
Restart a speciffic service: ``docker compose restart powersync``  
Stop a speciffic service: ``docker compose stop powersync``  
Start a speciffic service: ``docker compose up -d powersync``

### Log rotation
If log rotation is not set in docker-compose.yaml, truncate maually to free up space:
```truncate -s 0 $(docker inspect --format='{{.LogPath}}' <container_navn_eller_id>)```