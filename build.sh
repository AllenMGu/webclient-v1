#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
output_dir=${1:-"${script_dir}/build"}

if [ -z "${CONTAINER_ENGINE:-}" ]; then
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_ENGINE=podman
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_ENGINE=docker
  else
    echo 'Podman or Docker is required.' >&2
    exit 1
  fi
fi

mkdir -p "${output_dir}"
if find "${output_dir}" -mindepth 1 -print -quit | grep -q .; then
  echo "Output directory must be empty: ${output_dir}" >&2
  exit 1
fi

"${CONTAINER_ENGINE}" build \
  --platform linux/amd64 \
  --file "${script_dir}/Dockerfile" \
  --output "type=local,dest=${output_dir}" \
  "${script_dir}"

expected=fef91c15fa4b29d527878aea9f0a923b8b53a6aaaee4d99c61c926caddc74253
actual=$(sha256sum "${output_dir}/main.dart.js" | awk '{print $1}')
if [ "${actual}" != "${expected}" ]; then
  echo "Unexpected main.dart.js hash: ${actual}" >&2
  exit 1
fi

test -f "${output_dir}/corresponding-source/LICENCE"
test -f "${output_dir}/corresponding-source/rustdesk-source-47a7b7313bb906ebdae36bd16838bdefa8853639.tar"
test -f "${output_dir}/corresponding-source/overrides/flutter/lib/webclient_theme.dart"
echo "Web Client V1 built at ${output_dir}"
