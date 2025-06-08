#!/bin/bash

echo "🚀 Starting Full Setup..."

# ------------------ Setup001: Create Folder Structure & Clone Repository ------------------
echo "📁 Creating folder structure & cloning repository..."
mkdir -p dockerr/git-file
mkdir -p dockerr/minecraft-data
mkdir -p dockerr/playit  # still keeping in case you reuse it
mkdir -p dockerr/crafty-data

# Clone repository only if it doesn't exist
if [ ! -d "dockerr/git-file/.git" ]; then
    git clone https://github.com/vosoxrotp89/minxRr02 dockerr/git-file
else
    echo "✅ Repository already exists in git-file. Skipping clone."
fi

echo "⏳ Waiting 30 seconds to ensure everything is properly cloned..."
sleep 30

# ------------------ Setup002: Move Required Files ------------------
echo "📂 Moving Playit files & scripts..."
GIT_FILE_DIR="dockerr/git-file/dockerr"
PLAYIT_SRC="$GIT_FILE_DIR/playit"
PLAYIT_DEST="dockerr/playit"
MAIN_DEST="dockerr"

if [ -d "$PLAYIT_SRC" ] && [ -d "$PLAYIT_DEST" ]; then
    mv "$PLAYIT_SRC"/* "$PLAYIT_DEST"/
    echo "✅ Playit files moved successfully."
    mv "$GIT_FILE_DIR/start.sh" "$GIT_FILE_DIR/stop.sh" "$MAIN_DEST"/
    echo "✅ Start and stop scripts moved successfully."
else
    echo "❌ Error: Required directories not found!"
    exit 1
fi

echo "⏳ Waiting 30 seconds before proceeding..."
sleep 30

# ------------------ Setup003: Update start.sh & stop.sh Paths ------------------
echo "🔄 Updating start.sh with dynamic Codespace name..."
CODESPACE_NAME=$(basename "$(pwd)")
START_SH="dockerr/start.sh"

if [ -f "$START_SH" ]; then
    sed -i "s|/workspaces/[^/]*/dockerr|/workspaces/$CODESPACE_NAME/dockerr|g" "$START_SH"
    chmod +x "$START_SH"
    chmod +x "dockerr/stop.sh"
    echo "✅ start.sh & stop.sh updated and made executable."
else
    echo "❌ Error: start.sh not found!"
    exit 1
fi

echo "⏳ Waiting 30 seconds before setting up Crafty..."
sleep 30

# ------------------ Setup004: Set Up Crafty Controller ------------------
echo "🛠️ Setting up Crafty Controller..."
CRAFTY_CONTAINER="crafty"

if docker ps -a --format '{{.Names}}' | grep -q "^$CRAFTY_CONTAINER$"; then
    echo "📦 Crafty container already exists. Starting it..."
    docker start $CRAFTY_CONTAINER
else
    echo "🆕 Creating Crafty container..."
    docker run -d --name $CRAFTY_CONTAINER \
        -v "/workspaces/$CODESPACE_NAME/dockerr/crafty-data:/crafty/data" \
        -v "/workspaces/$CODESPACE_NAME/dockerr/minecraft-data:/crafty/servers" \
        -p 8443:8443 -p 25565:25565 \
        -e TZ=Etc/UTC -e CRAFTY_HOST=0.0.0.0 \
        registry.gitlab.com/crafty-controller/crafty-4:latest
fi

echo "⏳ Waiting 50 seconds for Crafty to initialize..."
sleep 50

# Fetch Crafty credentials
echo "🔑 Fetching Crafty default login credentials..."
if docker exec -it $CRAFTY_CONTAINER cat /crafty/app/config/default-creds.txt 2>/dev/null; then
    echo "✅ Credentials fetched successfully!"
else
    echo "⚠️ Warning: Could not fetch credentials! Check manually inside the container."
fi

# ------------------ Setup005: Deploy Twingate Connector ------------------
echo "🔌 Setting up Twingate Connector..."

cat <<EOF > dockerr/twingate.env
TWINGATE_NETWORK=vosoxrotp89
TWINGATE_ACCESS_TOKEN="eyJhbGciOiJFUzI1NiIsImtpZCI6IlBWZ3lTVVNvd0JUazA5cFZheS1FWWRVVHlLUHZOclBFdzdISjF2d0xBbGsiLCJ0eXAiOiJEQVQifQ.eyJudCI6IkFOIiwiYWlkIjoiNTM2MzMxIiwiZGlkIjoiMjI3NjAzOCIsInJudyI6MTc0OTMwMzM0NSwianRpIjoiOTZhNjQ2NmUtMDNkNS00NWM4LTlhNDMtNDY4NTI0ODRlMmRhIiwiaXNzIjoidHdpbmdhdGUiLCJhdWQiOiJ2b3NveHJvdHA4OSIsImV4cCI6MTc0OTMwNjYwNSwiaWF0IjoxNzQ5MzAzMDA1LCJ2ZXIiOiI0IiwidGlkIjoiMTQwNjM4Iiwicm5ldGlkIjoiMjA2MzExIn0.psTAk2JWcf2b4FKwRizzRtyE6UhQb3GknYnecqa6tO419hXAjh7194C06WEkGvtmFHEY_xql9iHdlqHCGLGsgw"
TWINGATE_REFRESH_TOKEN="mrK5EsQncb0M5azLc-3BlEH_rB0KX-OcmlNyRrfZ6azSKXUbPSHuiMIFqNTC7gvmwCicNjis10xjlZehg8cHBUtKe7_IcWmixUTjCpeiXjX31agtNvuwKhaNt8Vfr-3PRV78ng"
EOF

docker run -d \
  --name twingate-connector \
  --env-file dockerr/twingate.env \
  --restart unless-stopped \
  --cap-add=NET_ADMIN \
  --network=host \
  twingate/connector:latest

echo "⏳ Waiting 20 seconds for Twingate Connector to stabilize..."
sleep 20
echo "✅ Twingate Connector deployed."

echo "🎉 All setup steps completed!"
