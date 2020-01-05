#!/bin/bash
set -e

docker-compose down -v
docker-compose up --build -d
docker-compose exec app /usr/src/app/bin/boardr eval "Boardr.Release.migrate"
docker-compose logs -f app locust