#!/bin/bash
curl https://git.glassocean.hkn/runner-started

docker run --detach \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --env=DRONE_RPC_PROTO=https \
  --env=DRONE_RPC_HOST=drone.glassocean.hkn \
  --env=DRONE_RPC_SECRET=whZfjQQpAyPISaIy5pm0axVsF9Z0oXeA \
  --env=DRONE_RUNNER_CAPACITY=3 \
  --env=DRONE_RUNNER_NAME=runner-1 \
  --env=DRONE_RUNNER_VOLUMES=/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt,/var/run/docker.sock:/var/run/docker.sock \
  --volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
  --restart=always \
  --name=runner \
  drone/drone-runner-docker:1

# Dummy container to run in the background. The player is supposed to break into this
docker run --detach --name crystal-minnow -e API_KEY="DDC{N0W_TH3_R4T2_4R3_JUMP1NG_2H1P2}" registry.glassocean.hkn/crystal-minnow:1
