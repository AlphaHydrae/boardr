#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT="$( dirname "$DIR" )"

cd "$ROOT"
pushd load-testing 1>/dev/null

docker-compose down -v
docker-compose up --build -d
docker-compose exec api /usr/src/app/bin/boardr_api eval "Boardr.Release.migrate"
docker-compose logs -f api locust

popd
