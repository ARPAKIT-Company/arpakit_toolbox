docker stop arpakit_portainer
docker rm arpakit_portainer
docker run -d \
  -p 50533:8000 \
  -p 50534:9443 \
  -p 50537:9000 \
  --name arpakit_portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v arpakit_portainer_volume:/data \
  portainer/portainer-ce:latest
echo "http: 50534, https: 50537"