#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT="$( dirname "$DIR" )"

cd "$ROOT"
pushd load-testing 1>/dev/null

# Generate the RSA private key required to run the Boardr API.
if ! test -f tmp/id_rsa; then
  (umask 077 && mkdir -p tmp)
  pushd tmp 1>/dev/null
  ssh-keygen -b 1024 -C boardr -f id_rsa -t rsa -N ''
  ssh-keygen -p -m PEM -f id_rsa -P '' -N ''
  chmod 444 id_rsa
  popd
fi

docker-compose down -v
docker-compose up --build -d
docker-compose exec api /usr/src/app/bin/boardr_api eval "Boardr.Release.migrate"
docker-compose logs -f api locust

popd