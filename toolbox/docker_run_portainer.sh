HTTP_PORT=${1:-9000}

docker stop portainer
docker rm portainer
docker rmi portainer/portainer-ce:latest
docker pull portainer/portainer-ce:latest
docker run -d \
  -p ${HTTP_PORT}:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_volume:/data \
  portainer/portainer-ce:latest
echo "Portainer HTTP: ${HTTP_PORT}"