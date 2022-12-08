.DEFAULT_GOAL := help

docker-compose-production := docker-compose -p ceramic -f docker-compose.yml -f docker-compose.production.yml
docker-compose-local := docker-compose -p ceramic -f docker-compose.yml -f docker-compose.local.yml

local_start: ## create and start local Docker nodes
	${docker-compose-local} stop
	${docker-compose-local} rm -f caddy
	${docker-compose-local} build
	${docker-compose-local} up --build --remove-orphans --no-start
	${docker-compose-local} start

local_stop: ## stop local Docker nodes
	${docker-compose-local} stop

local_test: ## verify local Ceramic API node is accessible
	curl http://localhost:7007/api/v0/node/chains

remote_setup: ## ensure SSH user can access docker
	@[ -z "${SSH_HOST}" ] && { echo >&2 "Error: missing environment variable SSH_HOST"; exit 1; } || :
	ssh ${SSH_HOST} -- sudo usermod -aG docker \$USER

remote_start: docker_host="tcp://127.0.0.1:9999"
remote_start: ## deploy ceramic to remote host
	@[ -z "${SSH_HOST}" ] && { echo >&2 "Error: missing environment variable SSH_HOST"; exit 1; } || :
	@[ -z "${CERAMIC_DOMAIN}" ] && { echo >&2 "Error: missing environment variable CERAMIC_DOMAIN"; exit 1; } || :
	scp Caddyfile.production ${SSH_HOST}
	scp js-ceramic.daemon.config.production.json ${SSH_HOST}:
	ssh ${SSH_HOST} \
		"sudo mkdir -p /var/lib/docker-compose && \
		sudo mv Caddyfile.production js-ceramic.daemon.config.production.json /var/lib/docker-compose"
	ssh -L127.0.0.1:9999:/var/run/docker.sock -tt ${SSH_HOST} &
	sleep 5
	DOCKER_HOST="${docker_host}" ${docker-compose-production} stop
	DOCKER_HOST="${docker_host}" ${docker-compose-production} rm -f caddy
	DOCKER_HOST="${docker_host}" ${docker-compose-production} build
	DOCKER_HOST="${docker_host}" ${docker-compose-production} up --build --remove-orphans --no-start
	DOCKER_HOST="${docker_host}" ${docker-compose-production} start
	lsof -i ":9999" -s TCP:LISTEN -t | xargs -IRE -n 1 kill RE

remote_stop: docker_host="tcp://127.0.0.1:9999"
remote_stop: ## stop remote Docker nodes
	@[ -z "${SSH_HOST}" ] && { echo >&2 "Error: missing environment variable SSH_HOST"; exit 1; } || :
	@[ -z "${CERAMIC_DOMAIN}" ] && { echo >&2 "Error: missing environment variable CERAMIC_DOMAIN"; exit 1; } || :
	ssh -L127.0.0.1:9999:/var/run/docker.sock -tt ${SSH_HOST} &
	sleep 5
	docker-compose -p ceramic -f docker-compose.yml -f docker-compose.production.yml down
	DOCKER_HOST="${docker_host}" ${docker-compose-production} stop
	lsof -i ":9999" -s TCP:LISTEN -t | xargs -IRE -n 1 kill RE

remote_test: ## verify local Ceramic API node is accessible
	@[ -z "${CERAMIC_DOMAIN}" ] && { echo >&2 "Error: missing environment variable CERAMIC_DOMAIN"; exit 1; } || :
	curl https://${CERAMIC_DOMAIN}/api/v0/node/chains

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.PHONY: local_start local_stop local_test
.PHONY: remote_start remote_stop remote_test
