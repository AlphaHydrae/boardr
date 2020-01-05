# Notes

# Observe running container

Open SSH tunnels to EMPD and erlang node:

```bash
ssh -L 4369:127.0.0.1:4369 -L 9000:127.0.0.1:9000 ssh://boardr@127.0.0.1:2222
```

Run an IEx session with the same cookie:

```bash
cd performance
export ERLANG_COOKIE="$(docker-compose exec app cat /usr/src/app/releases/COOKIE)"
cd ../server
iex --name "foo@127.0.0.1" --cookie "$ERLANG_COOKIE"
```