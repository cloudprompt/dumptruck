#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

main() {
	echo "$CRONTAB" > crontab
	#echo "$CONFIG_JSON" > config.json

	echo $VCAP_SERVICES | ./jq '{ encryption: "supersecret", sources: [ (foreach ."osb-postgresql"[] as $db (1; { name:$db.name, dbtype:"postgres", host: $db.credentials.uri | match("@(.*?):").captures[0].string, database:$db.credentials.database, username:$db.credentials.user, password:$db.credentials.password }))], "storage": [{"type": "swift","auth_url": "https://os.eu-de-darz.msh.host:5000/v3","username": "ZnQEXo405u","user_domain_id": "306b7c42140e4e87b91005b8c1822c0e","password": "ClRu0LVT0Nc4ZfuoOa8Xpaom","project_id": "c816996d45df4f098e8a4250bdab2aa8","container_url": "https://swift.os.eu-de-darz.msh.host/swift/v1/BackupsOfLive"}], "monitor": { "url": "https://ourpushgateway/", "username": "push", "password": "********" } }' > config.json


	echo "${CONFIG_RCLONE:-}" > rclone

	./supercronic /app/crontab 2>&1
}

main "$@"
