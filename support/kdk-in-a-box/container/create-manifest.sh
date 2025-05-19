#!/bin/bash

usage() {
  echo "Error: ${1}"

  echo "Usage: ${0} <manifest name>"
}

if [ -z "${1}" ]; then
  usage "Must specify manifest name as first arg"
fi

MANIFEST_NAME=$1
if [[ -n $CI_REGISTRY_IMAGE ]]; then
  MANIFEST_NAME="$CI_REGISTRY_IMAGE/$MANIFEST_NAME"
fi

echo "Creating manifest with name: ${MANIFEST_NAME}"
echo "Docker image name: ${DOCKER_IMAGE_NAME}"

docker manifest create "$MANIFEST_NAME" \
  --amend "$MANIFEST_NAME-arm64" \
  --amend "$MANIFEST_NAME-amd64"

echo "Pushing manifest..."
docker manifest push "$MANIFEST_NAME"

# Create latest tag if we are on the default branch
if [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then
  echo "On default branch - creating latest tag..."
  IMAGE_BASE=$(echo $DOCKER_IMAGE_NAME | cut -d':' -f1)
  docker manifest create "$CI_REGISTRY_IMAGE/$IMAGE_BASE:latest" \
    --amend "$MANIFEST_NAME-arm64" \
    --amend "$MANIFEST_NAME-amd64"

  echo "Pushing latest manifest..."
  docker manifest push "$CI_REGISTRY_IMAGE/$IMAGE_BASE:latest"
fi
