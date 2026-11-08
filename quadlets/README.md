# Overt Dedicated Quadlets

## Synapse Setup

Run these commands once before starting the synapse service

`PGPASS=$(openssl rand -hex 24)`
`printf <user> | podman secret create pg_user -`
`printf '%s' "$PGPASS" | podman secret create pg_password -`

`systemctl --user daemon-reload`

```
podman run --rm -v synapse-data:/data \
  -e SYNAPSE_SERVER_NAME=sub.domain.com -e SYNAPSE_REPORT_STATS=no \
  docker.io/matrixdotorg/synapse:latest generate
```

Configure the postgres db in `homeserver.yaml`

`podman unshare nvim "$(podman volume inspect synapse-data --format '{{.Mountpoint}}')/homeserver.yaml"`

```homeserver.yaml
database:
  name: psycopg2
  args:
    user: <user>
    password: <value of $PGPASS>
    dbname: synapse
    host: 127.0.0.1
    cp_min: 5
    cp_max: 10
```
