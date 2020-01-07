#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT="$( dirname "$DIR" )"

cd "$ROOT"

# Generate the RSA private key required to run the Boardr API.
if ! test -f server/tmp/id_rsa; then
  pushd server 1>/dev/null
  (umask 077 && mkdir -p tmp)
  pushd tmp 1>/dev/null
  ssh-keygen -b 1024 -C boardr -f id_rsa -t rsa -N ''
  ssh-keygen -p -m PEM -f id_rsa -P '' -N ''
  popd
  popd
fi