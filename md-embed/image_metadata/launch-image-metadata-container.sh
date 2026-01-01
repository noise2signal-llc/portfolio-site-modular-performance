#!/bin/bash

set -e

CONTAINER_NAME="image-metadata-tagger"
GIT_ROOT="$(git rev-parse --show-toplevel)"

FORCE_REBUILD=false
if [[ "$1" == "--force-rebuild" ]]; then
  FORCE_REBUILD=true
  shift
fi

if podman ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  if [[ "$FORCE_REBUILD" == true ]]; then
    podman stop "$CONTAINER_NAME"
  else
    podman exec -it "$CONTAINER_NAME" /workspace/md-embed/image_metadata/embed-image-metadata.sh
    exit 0
  fi
fi

if podman ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  if [[ "$FORCE_REBUILD" == true ]]; then
    podman rm "$CONTAINER_NAME"
  else
    podman start "$CONTAINER_NAME"
    podman exec -it "$CONTAINER_NAME" /workspace/md-embed/image_metadata/embed-image-metadata.sh
    exit 0
  fi
fi

podman build -t "$CONTAINER_NAME" -f "$GIT_ROOT/md-embed/image_metadata/Dockerfile" "$GIT_ROOT/md-embed/image_metadata"

podman run --rm \
  --name "$CONTAINER_NAME" \
  --userns=keep-id \
  -v "$GIT_ROOT:/workspace" \
  -w /workspace \
  "$CONTAINER_NAME"
