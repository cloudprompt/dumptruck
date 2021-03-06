#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

main() {

  echo "$CRONTAB" > crontab
  echo "$STORAGE" > storage.json
  
  echo "${CONFIG_RCLONE:-}" > rclone

  echo -e '[LiveSwift]' >> rclone
  echo $VCAP_SERVICES | ./jq --raw-output 'foreach ."user-provided"[].credentials as $swift (1; {type:"swift", user:$swift.OS_USERNAME, key:$swift.OS_PASSWORD, auth:$swift.OS_AUTH_URL, tenant_id:$swift.OS_PROJECT_ID, domain:$ENV.SWIFTDOMAIN, storage_url:$ENV.SWIFTSTORAGEURL}) | to_entries | map("\(.key)=\(.value)") | .[]' >> rclone
  
  echo -e '[Backup]' >> rclone
  echo $STORAGE | ./jq --raw-output 'foreach ."storage"[0] as $swift (1; {type:"swift", user:$swift.username, key:$swift.password, auth:$swift.auth_url, tenant_id:$swift.project_id, domain:$ENV.SWIFTDOMAIN, storage_url:$ENV.SWIFTSTORAGEURL }) | to_entries | map("\(.key)=\(.value)") | .[]' >> rclone
  
  echo $VCAP_SERVICES | ./jq '{encryption:$ENV.ENCRYPTION,sources: [ (foreach ."osb-postgresql"[] as $db (1; {name:$db.name, dbtype:"postgres", host:$db.credentials.uri | match("@(.*?):").captures[0].string, database:$db.credentials.database, username:$db.credentials.user, password:$db.credentials.password, keep:$ENV.KEEPBACKUPS }))]}' > sources.json

  ### merge all JSON files to one (expecting exactly two files, storage & sources !)
  ./jq -s '.[0]*.[1]' *.json > config.json

  ./supercronic /app/crontab 2>&1

}

main "$@"