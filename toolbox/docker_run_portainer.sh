docker stop portainer
docker rm portainer
docker run -d \
  -p 8000:8000 \
  -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_volume:/data \
  portainer/portainer-ce:latest
echo "http: 9000, for agents: 8000"