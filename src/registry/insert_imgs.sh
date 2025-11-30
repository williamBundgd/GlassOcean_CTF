# docker login https://registry.glassocean.hkn -u docker -p EPKjub1iziolDfl

docker pull python:buster
docker tag python:buster registry.glassocean.hkn/python:buster
# docker push registry.glassocean.hkn/python:buster
docker image rm python:buster
# docker image rm registry.glassocean.hkn/python:buster

docker pull docker:latest
docker tag docker:latest registry.glassocean.hkn/docker:1
# docker push registry.glassocean.hkn/docker:1
docker image rm docker:latest
# docker image rm registry.glassocean.hkn/docker:1

docker pull ubuntu:20.04
docker tag ubuntu:20.04 registry.glassocean.hkn/ubuntu:20.04
# docker push registry.glassocean.hkn/ubuntu:20.04
docker image rm ubuntu:20.04
# docker image rm registry.glassocean.hkn/ubuntu:20.04

# docker pull drone/git
# docker tag drone/git registry.glassocean.hkn/drone/git
# docker push registry.glassocean.hkn/drone/git

docker pull mysql:5.7
docker tag mysql:5.7 registry.glassocean.hkn/mysql:5.7
# docker push registry.glassocean.hkn/mysql:5.7
docker image rm mysql:5.7
# docker image rm registry.glassocean.hkn/mysql:5.7

docker pull postgres:13.2
docker tag postgres:13.2 registry.glassocean.hkn/postgres:13.2
# docker push registry.glassocean.hkn/postgres:13.2
docker image rm postgres:13.2
# docker image rm registry.glassocean.hkn/postgres:13.2

# docker logout https://registry.glassocean.hkn
