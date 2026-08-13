#!/bin/sh
set -eu

source_commit=47a7b7313bb906ebdae36bd16838bdefa8853639
expected_archive=f943ce011eb2f8dc3056326cfb265e4bcf3721daea5512e4b57181ffd46f3950
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
archive="${script_dir}/rustdesk-source-${source_commit}.tar"
output_dir=${1:-"${script_dir}/source"}

actual_archive=$(sha256sum "${archive}" | awk '{print $1}')
if [ "${actual_archive}" != "${expected_archive}" ]; then
  echo "Unexpected source archive hash: ${actual_archive}" >&2
  exit 1
fi

mkdir -p "${output_dir}"
if find "${output_dir}" -mindepth 1 -print -quit | grep -q .; then
  echo "Source output directory must be empty: ${output_dir}" >&2
  exit 1
fi

tar -xf "${archive}" -C "${output_dir}"
file_count=$(find "${output_dir}" -type f | wc -l | tr -d ' ')
if [ "${file_count}" != 478 ]; then
  echo "Expected 478 source files, got ${file_count}" >&2
  exit 1
fi

printf '%s  %s\n' \
  8486a10c4393cee1c25392769ddd3b2d6c242d6ec7928e1414efff7dfb2f07ef \
  "${output_dir}/LICENCE" \
  | sha256sum --check --strict

echo "Extracted complete source to ${output_dir}"
