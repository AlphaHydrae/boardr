#!/bin/bash
set -e

function help {
  echo "Creates sample data in the Boardr API running on http://localhost:4000"
  echo
  echo "Usage:"
  echo "  ./scripts/sample-data.sh [OPTIONS]..."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help
      exit 0
    ;;
    *)
    # unknown option
    ;;
  esac
  shift # past argument or value
done

project_dir="$(cd "$(dirname $(dirname "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
tmp_dir="${project_dir}/tmp"
tmp_response_file="${tmp_dir}/response.json"

function cleanup() {
  rm -f "$tmp_response_file"
}

trap cleanup EXIT

echo

mkdir -p "$tmp_dir"

echo "Wiping out database..."
psql boardr -c 'DELETE FROM moves; DELETE FROM players; DELETE FROM games; DELETE FROM users; DELETE FROM identities;'
echo

# Create a first identity.
http \
  --download --output "$tmp_response_file" --print bBhH \
  :4000/api/identities "email=john.doe@boardr.local" "provider=local"

echo

export BOARDR_TOKEN="$(cat "$tmp_response_file"|jq -r "._embedded.\"boardr:token\".value")"

# Create a first user (John Doe).
http \
  --download --output "$tmp_response_file" --print bBhH \
  :4000/api/users "Authorization:Bearer $BOARDR_TOKEN" "name=john-doe"

export BOARDR_TOKEN="$(cat "$tmp_response_file"|jq -r "._embedded.\"boardr:token\".value")"

echo

# Create a second identity.
http \
  --download --output "$tmp_response_file" --print bBhH \
  :4000/api/identities "email=jane.doe@boardr.local" "provider=local"

echo

export BOARDR_OTHER_TOKEN="$(cat "$tmp_response_file"|jq -r "._embedded.\"boardr:token\".value")"

# Create a second user (Jane Doe).
http \
  --download --output "$tmp_response_file" --print bBhH \
  :4000/api/users "Authorization:Bearer $BOARDR_OTHER_TOKEN" "name=jane-doe"

export BOARDR_OTHER_TOKEN="$(cat "$tmp_response_file"|jq -r "._embedded.\"boardr:token\".value")"

echo

# Create a game.
http \
  --download --output "$tmp_response_file" --print bBhH \
  :4000/api/games "Authorization:Bearer $BOARDR_TOKEN" "title=Sample data"

players_url="$(cat "$tmp_response_file"|jq -r "._links.\"boardr:players\".href")"
echo

# Make John Doe join the game.
http \
  --download --output "$tmp_response_file" --print bBhH \
  POST "$players_url" "Authorization:Bearer $BOARDR_TOKEN"

echo

# Make Jane Doe join the game.
http \
  --download --output "$tmp_response_file" --print bBhH \
  POST "$players_url" "Authorization:Bearer $BOARDR_OTHER_TOKEN"

echo