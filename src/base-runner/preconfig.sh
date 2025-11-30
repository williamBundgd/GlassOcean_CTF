docker pull docker:latest
docker tag docker:latest docker:1
docker tag docker:latest docker:2
docker tag docker:latest docker:3

docker pull ubuntu:20.04

docker pull python:3.11-alpine

docker pull nginx:alpine  # For dummy container
docker tag nginx:alpine registry.glassocean.hkn/crystal-minnow:1
docker image rm nginx:alpine

docker pull drone/git  # Used by Drone to clone git repo

docker pull drone/drone-runner-docker:1  # Drone Runner docker image

echo "DDC{TH3_CH1CK3N_H42_3SC4P3D_TH3_P3N}" > /flag.txt  # Flag stored on the runner host machine

cat /mnt/config/glassoceanCA.pem >> /etc/ssl/certs/ca-certificates.crt  # ca-certificates
poweroff
