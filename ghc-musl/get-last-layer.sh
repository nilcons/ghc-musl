#!/bin/sh

set -e

REPO=$1
TAG=$2

TOKEN=$(curl -s "https://auth.docker.io/v2/token/?service=registry.docker.io&scope=repository:$REPO:pull" | jq -r .token)
TARSUM=$(curl -s -H Authorization:\ Bearer\ $TOKEN https://registry-1.docker.io/v2/$REPO/manifests/$TAG | jq -r '.fsLayers[0].blobSum')

curl -L -H Authorization:\ Bearer\ $TOKEN https://registry-1.docker.io/v2/$REPO/blobs/$TARSUM
