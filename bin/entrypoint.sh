#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

main() {
  
  echo "$CRONTAB" > crontab
  echo "${CONFIG_RCLONE:-}" > rclone

  ### copy the required environment variables to JSON files
  #echo "$ENCRYPTION" > encryption.json
  echo "$STORAGE" > storage.json

  echo $VCAP_SERVICES | ./jq '{encryption:$ENV.ENCKEY, sources: [ (foreach ."osb-postgresql"[] as $db (1; { name:$db.name, dbtype:"postgres", host: $db.credentials.uri | match("@(.*?):").captures[0].string, database:$db.credentials.database, username:$db.credentials.user, password:$db.credentials.password, keep:$ENV.KEEPBACKUPS }))]}' > sources.json

  ### merge all JSON files to one (expecting exactly two files !)
  ./jq -s '.[0]*.[1]' *.json > config.json


  ./supercronic /app/crontab 2>&1
}

main "$@"
