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

