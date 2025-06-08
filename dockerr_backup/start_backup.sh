#!/bin/bash

echo "Starting Crafty Controller..."
cd /workspaces/cloudfrMC/dockerr

docker start crafty || docker run -d --name crafty \
-v /workspaces/cloudfrMC/dockerr/crafty-data:/crafty/data \
-v /workspaces/cloudfrMC/dockerr/minecraft-data:/crafty/servers \
-p 8443:8443 \
-p 25565:25565 \
-e TZ=Etc/UTC \
-e CRAFTY_HOST=0.0.0.0 \
registry.gitlab.com/crafty-controller/crafty-4:latest

# Optional: Start Twingate if not already running (safe fallback)
#echo "Checking Twingate Connector..."
#docker start twingate-connector 2>/dev/null || echo "Twingate already running or will auto-start on reboot."

#echo "✅ All services started."
