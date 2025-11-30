#!/bin/bash
set -m
./entrypoint.sh /etc/docker/registry/config.yml &
while true
do
health=$(curl -k --write-out %{http_code} --silent --output /dev/null https://$REGISTRY_HTTPS_ADDR)
if [ "$health" -eq 200 ]; then
        echo "Registry is ready. Continue with setup..."
        break
else 
        echo "Registry is not ready. Waiting 5 seconds..."
        sleep 5
fi
done

fg # Bring the registry process back to the foreground
