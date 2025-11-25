#!/bin/bash
# portainer-updater.sh
# Safe Portainer update script for DietPi / Docker
# Preserves data and allows rollback

# Configuration
OLD_CONTAINER="portainer"
NEW_CONTAINER="portainer_new"
ROLLBACK_CONTAINER="portainer_old"
WEB_PORT="9002"
DATA_VOLUME="portainer_data"
SSL_CERT="/etc/ssl/certs/ca-certificates.crt"

echo "=== Pulling latest Portainer image ==="
docker pull portainer/portainer-ce:latest

echo "=== Stopping old container ==="
docker stop ${OLD_CONTAINER}

echo "=== Starting new Portainer container ==="
docker run -d \
  -p ${WEB_PORT}:9000 \
  --name ${NEW_CONTAINER} \
  --restart=always \
  -v ${DATA_VOLUME}:/data \
  -v ${SSL_CERT}:${SSL_CERT}:ro \
  -v /run/docker.sock:/var/run/docker.sock \
  portainer/portainer-ce:latest

echo "=== Waiting for new container to start ==="
sleep 5
docker logs -f ${NEW_CONTAINER} --tail 20

echo "=== Stopping new container ==="
docker stop ${NEW_CONTAINER}

echo "=== Renaming old container for rollback ==="
docker rename ${OLD_CONTAINER} ${ROLLBACK_CONTAINER}

echo "=== Renaming new container to original name ==="
docker rename ${NEW_CONTAINER} ${OLD_CONTAINER}

echo "=== Starting updated container ==="
docker start ${OLD_CONTAINER}

echo "=== Update complete ==="
echo "Portainer is running on port ${WEB_PORT}. Old container saved as ${ROLLBACK_CONTAINER} for rollback."
