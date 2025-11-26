docker stop portainer
docker rm portainer
docker pull portainer/portainer-ce:2.33.2

docker run -d \
  -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_volume:/data \
  portainer/portainer-ce:latest
echo "http: 9000"