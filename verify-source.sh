#!/bin/sh
set -eu

source_repository=https://github.com/JelleBuning/rustdesk.git
source_commit=47a7b7313bb906ebdae36bd16838bdefa8853639
expected_archive=f943ce011eb2f8dc3056326cfb265e4bcf3721daea5512e4b57181ffd46f3950
expected_license=8486a10c4393cee1c25392769ddd3b2d6c242d6ec7928e1414efff7dfb2f07ef
expected_main=2112e6feed7220924ad1022b73d175d4d2c608cf9e07038bf4973e6a4c05838e

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_root=$(CDPATH= cd -- "${script_dir}/.." && pwd)
temporary_root=$(mktemp -d)
trap 'rm -rf "${temporary_root}"' EXIT HUP INT TERM
bundled_archive="${script_dir}/rustdesk-source-${source_commit}.tar"

actual_bundled_archive=$(sha256sum "${bundled_archive}" | awk '{print $1}')
if [ "${actual_bundled_archive}" != "${expected_archive}" ]; then
  echo "Unexpected bundled source archive hash: ${actual_bundled_archive}" >&2
  exit 1
fi

git init --quiet "${temporary_root}/upstream"
git -C "${temporary_root}/upstream" remote add origin "${source_repository}"
git -C "${temporary_root}/upstream" fetch --quiet --depth=1 origin "${source_commit}"
test "$(git -C "${temporary_root}/upstream" rev-parse FETCH_HEAD)" = "${source_commit}"

git -C "${temporary_root}/upstream" archive --format=tar FETCH_HEAD > "${temporary_root}/source.tar"
actual_archive=$(sha256sum "${temporary_root}/source.tar" | awk '{print $1}')
if [ "${actual_archive}" != "${expected_archive}" ]; then
  echo "Unexpected upstream archive hash: ${actual_archive}" >&2
  exit 1
fi

cmp "${temporary_root}/source.tar" "${bundled_archive}"

actual_license=$(sha256sum "${script_dir}/LICENCE" | awk '{print $1}')
if [ "${actual_license}" != "${expected_license}" ]; then
  echo "Unexpected AGPL license hash: ${actual_license}" >&2
  exit 1
fi

tar -xOf "${bundled_archive}" LICENCE | cmp - "${script_dir}/LICENCE"

for overlay in \
  flutter/lib/main.dart \
  flutter/lib/webclient_theme.dart \
  flutter/lib/pages/home_page.dart \
  flutter/lib/pages/connection_page.dart \
  flutter/lib/pages/web_settings_page.dart
do
  test -f "${script_dir}/overrides/${overlay}"
done

if find "${script_dir}/overrides" -type l -print -quit | grep -q .; then
  echo "UI source overlays must not contain symbolic links" >&2
  exit 1
fi

if [ -d "${repository_root}/resources/web/js" ]; then
  diff --recursive --brief --no-dereference \
    "${repository_root}/resources/web/js" \
    "${script_dir}/integration/resources-web-js"
  cmp "${repository_root}/resources/web/SOURCE.html" "${script_dir}/SOURCE.html"
  cmp "${repository_root}/resources/web/NOTICE" "${script_dir}/NOTICE"
  cmp "${repository_root}/resources/web/AGPL-3.0.txt" "${script_dir}/LICENCE"
  printf '%s  %s\n' \
    "${expected_main}" \
    "${repository_root}/resources/web/main.dart.js" \
    | sha256sum --check --strict
fi

echo "Verified complete source at ${source_commit}"
