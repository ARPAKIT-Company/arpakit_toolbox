docker pull portainer/portainer-ce:2.33.2
docker stop arpakit_portainer
docker rm arpakit_portainer
docker run -d \
  -p 50533:8000 \
  -p 50534:9443 \
  --name arpakit_portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v arpakit_portainer_volume:/data \
  portainer/portainer-ce:latest