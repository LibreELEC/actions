#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

set -e

# set version to use
# check for format 9.2.0 instead of 9.2
if [[ "$1" =~ ^[0-9]{1,2}.[0-9]{1,3}.[0-9]{1,3}$ ]]; then
  REPO_VERSION="$1"
else
  echo -e "\nUsage:"
  echo -e "${0##*/} 9.2.0"
  echo -e "${0##*/} 10.80.3"
  echo -e "all necessary folders are created automatically"
  exit 1
fi

# variables
PATH_STAGING="/var/www/addon-upload/${REPO_VERSION}/"
PATH_TARGET="/var/www/addon-temp/${REPO_VERSION}"
PATH_LOG="/var/www/addon-upload/addon-${REPO_VERSION}.log"
PATH_ADDON_REPO="/var/www/addons/${REPO_VERSION}"

#### functions

# emit JSON result to stdout for GHA to consume and post to Slack
emit_result() {
  local error_msg="${1:-}"
  ERROR_MSG="${error_msg}" REPO_VERSION="${REPO_VERSION}" \
  python3 - "${PATH_LOG}" "${BAD_CHECKSUMS_FILE}" << 'PYEOF'
import json, sys, os

version = os.environ.get('REPO_VERSION', '')
error_msg = os.environ.get('ERROR_MSG', '')
log_path, warnings_path = sys.argv[1], sys.argv[2]

warnings = []
try:
    with open(warnings_path) as f:
        warnings = [line.strip() for line in f if line.strip()]
except (FileNotFoundError, OSError):
    pass

addons_by_arch = {}
arch_order = []
try:
    with open(log_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split('/')
            if len(parts) >= 4:
                key = f'{parts[0]} {parts[1]}'
                if key not in addons_by_arch:
                    addons_by_arch[key] = []
                    arch_order.append(key)
                filename = parts[-1]
                addons_by_arch[key].append(filename[:-4] if filename.endswith('.zip') else filename)
except (FileNotFoundError, OSError):
    pass

result = {
    'version': version,
    'warnings': warnings,
    'architectures': [{'label': k, 'addons': addons_by_arch[k]} for k in arch_order],
}
if error_msg:
    result['error'] = error_msg
print(json.dumps(result))
PYEOF
}

# create addon.xml
create_addon_xml(){
  while IFS= read -r PROJECT; do
    while IFS= read -r ARCH; do
      ARCH_XML='<?xml version="1.0" encoding="UTF-8"?>\n<addons>\n'
      while IFS= read -r ADDON; do
        while IFS= read -r ARCHIVE; do
          if [ -n "${ARCHIVE}" ]; then
            ARCHIVE_XML=$(unzip -pv "${ARCHIVE}" "${ADDON}/addon.xml" | sed '1d' | cat)
            ARCH_XML="${ARCH_XML}${ARCHIVE_XML}\n"
          fi
        done < <(find "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}/${ADDON}" -type f -name "*.zip" | sort -V)
      done < <(find "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
      ARCH_XML="${ARCH_XML}</addons>"
      echo -e "${ARCH_XML}" > "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}/addons.xml"
      gzip -f "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}/addons.xml"
      md5sum "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}/addons.xml.gz" \
        | cut -f1 -d ' ' > "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}/addons.xml.gz.md5"
      sha256sum "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}/addons.xml.gz" \
        | cut -f1 -d ' ' > "${PATH_ADDON_REPO}/${PROJECT}/${ARCH}/addons.xml.gz.sha256"
    done < <(find "${PATH_ADDON_REPO}/${PROJECT}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
  done < <(find "${PATH_ADDON_REPO}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
}

###############

BAD_CHECKSUMS_FILE=$(mktemp)
trap 'rm -f "${BAD_CHECKSUMS_FILE}"' EXIT

# check if jenkins addons are available
if [ ! -d "${PATH_STAGING}" ]; then
  emit_result "no staging folder for ${REPO_VERSION}"
  exit 0
fi

# exit cleanly if no add-on zips are staged
compgen -G "${PATH_STAGING}*.zip" > /dev/null 2>&1 || exit 0

# preparing folder
mkdir -p "${PATH_TARGET}" "${PATH_ADDON_REPO}"

# check for enough free disk space
if [[ $(df "${PATH_ADDON_REPO}" | awk 'END {print $4}') -lt 6000000 ]]; then
  emit_result "not enough storage ($(df -h "${PATH_ADDON_REPO}" | awk 'END {print $4}') free)"
  exit 0
fi

# kill log
if [ -f "${PATH_LOG}" ]; then
  rm -f "${PATH_LOG}"
fi

touch "${PATH_LOG}"

# create target dir
mkdir -p "${PATH_TARGET}"

# check for sha256sum - collect failures instead of posting one-per-file
for PROJECT in "${PATH_STAGING}"/*.zip; do
  cd "${PATH_STAGING}" || exit
  if sha256sum --status -c "${PROJECT}.sha256" 2>&1; then
    continue
  else
    mv "${PROJECT}" "${PROJECT}"-ohohhhhh
    echo "${PROJECT##*/}" >> "${BAD_CHECKSUMS_FILE}"
  fi
done

# rename and move files to files
for PROJECT in "${PATH_STAGING}"/*.zip; do
  PROJECT="${PROJECT##*/}"
  # shellcheck disable=SC2034  # var1 documents the field layout; it is not used further
  var1=$(echo "${PROJECT}" | cut -d- -f1 )                             # 9.0
  var2=$(echo "${PROJECT}" | cut -d- -f2 )                             # Generic
  var3=$(echo "${PROJECT}" | cut -d- -f3 )                             # Could be either ARCH (x86_64) or legacy
  if [[ ${var2} == "Generic" && ${var3} == "legacy" ]]; then
    var2="Generic-legacy"
    var3=$(echo "${PROJECT}" | cut -d- -f4 )                             # x86_64
    var4=$(echo "${PROJECT}" | cut -d- -f5- | rev | cut -d- -f2- | rev ) # tools.ffmpeg-tools
    var5=$(echo "${PROJECT}" | cut -d- -f5- )                            # tools.ffmpeg-tools-9.0.102.zip
  else
    var4=$(echo "${PROJECT}" | cut -d- -f4- | rev | cut -d- -f2- | rev ) # tools.ffmpeg-tools
    var5=$(echo "${PROJECT}" | cut -d- -f4- )                            # tools.ffmpeg-tools-9.0.102.zip
  fi

# addon folder structure
# path-to-folder/Generic/x86_64/9.0/tools.ffmpeg-tools
  PATH_ADDON="${PATH_TARGET}/${var2}/${var3}/${var4}"
  if [ -e "${PATH_ADDON}/${var5}" ]; then
    continue
  else
    mkdir -p "${PATH_ADDON}"
    unzip -qn "${PATH_STAGING}"/"${PROJECT}" -d "${PATH_ADDON}"
  fi
done

# rsync to repo folder
mkdir -p "${PATH_ADDON_REPO}"
rsync --ignore-existing -vrh "${PATH_TARGET}"/* "${PATH_ADDON_REPO}" | grep .zip > "${PATH_LOG}" || true

# create addon.xml
create_addon_xml

# emit JSON result for GHA
emit_result

exit 0
