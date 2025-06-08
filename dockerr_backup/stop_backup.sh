#!/bin/bash

echo "Stopping Twingate Connector..."
docker stop twingate-connector

echo "Stopping Crafty Controller..."
docker stop crafty

echo "✅ All services stopped."
