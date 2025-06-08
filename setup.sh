#!/bin/bash

echo "🚀 Starting Full Setup..."

# ------------------ Setup000: Install Zerotier on Host ------------------

ZEROTIER_NET_ID="9f77fc393e9009e0"  # Replace with your actual network ID

echo "🔧 Checking Zerotier installation on host..."
if ! command -v zerotier-cli &> /dev/null
then
    echo "❌ Zerotier not found, installing..."
    curl -s https://install.zerotier.com | sudo bash
fi

echo "🚀 Starting Zerotier daemon manually..."
nohup zerotier-one > /dev/null 2>&1 &

sleep 5

echo "➕ Joining Zerotier network $ZEROTIER_NET_ID..."
zerotier-cli join $ZEROTIER_NET_ID

echo "⏳ Waiting 10 seconds for Zerotier to join network..."
sleep 10

echo "🔎 Zerotier status and IP addresses:"
zerotier-cli info
ip -4 addr show | grep zt

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

echo "🎉 All setup steps completed!"
