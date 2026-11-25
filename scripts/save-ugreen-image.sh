#!/bin/sh
# Pack the published LibreDB Studio image for a UGREEN NAS.
# UGREEN DXP models are x86_64, so this always takes linux/amd64,
# even when you run it on an Apple Silicon Mac.
#
# A direct `docker save` of the registry image fails on Docker Desktop: the
# manifest lists an attestation blob this machine does not have. Rebuilding
# FROM that image with provenance turned off writes a single-platform image
# `docker save` can pack. Nothing in the app is compiled.
#
# Usage:
#   ./scripts/save-ugreen-image.sh
#
# Then copy libredb-studio-latest.tar to the NAS and import it:
#   Docker → Image → Import
# Create a Project from docker-compose.nas.yml.

set -e

cd "$(dirname "$0")/.."

SRC="${SRC:-ghcr.io/libredb/libredb-studio:latest}"
IMAGE="${IMAGE:-libredb-studio}"
TAG="${TAG:-latest}"
PLATFORM="${PLATFORM:-linux/amd64}"
OUT="${IMAGE}-${TAG}.tar"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
printf 'FROM %s\n' "$SRC" > "$workdir/Dockerfile"

echo "Packing ${SRC} as ${IMAGE}:${TAG} for ${PLATFORM}"
docker buildx build \
  --platform "$PLATFORM" \
  --provenance=false \
  --sbom=false \
  -f "$workdir/Dockerfile" \
  -t "${IMAGE}:${TAG}" \
  --load \
  "$workdir"

echo "Saving ${OUT}"
docker save "${IMAGE}:${TAG}" -o "$OUT"

echo
echo "Done: $(pwd)/${OUT}"
echo "Copy that file to the NAS and import it in Docker → Image → Import."
echo "Then create a Project from docker-compose.nas.yml."
echo "In Studio, open each NAS database at host host.docker.internal and the port that container publishes."
