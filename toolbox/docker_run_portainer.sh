docker stop arpakit_portainer
docker rm arpakit_portainer
docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  -p 9000:9000 \
  --name arpakit_portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v arpakit_portainer_volume:/data \
  portainer/portainer-ce:latest
echo "http: 9443, https: 50537"