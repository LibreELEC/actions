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

# slack variables
slack_webhook_url="$2"
slack_channel="$3"

# variables
PATH_STAGING="/var/www/addon-upload/${REPO_VERSION}/"
PATH_TARGET="/var/www/addon-temp/${REPO_VERSION}"
PATH_LOG="/var/www/addon-upload/addon-${REPO_VERSION}.log"
PATH_ADDON_REPO="/var/www/addons/${REPO_VERSION}"

#### functions

# slack notification function
slack () {
  username="ADDON Bot"
  color="good" #good, warning, danger or HEX value
  text=$*
  if [[ ${text} == "" ]]; then
    while IFS= read -r line; do
      text="${text}${line}\n"
    done
  fi
  escapedText=$(echo "${text}" | sed 's/"/\"/g' | sed "s/'/\'/g" )
  json="{\"channel\": \"${slack_channel}\", \"username\":\"${username}\", \"icon_emoji\":\"ghost\", \"attachments\":[{\"color\":\"${color}\" , \"text\": \"${escapedText}\"}]}"
  curl -s -d "payload=${json}" "${slack_webhook_url}" || true
}

# pretty up the rsync log
rsync_log () {
  # header text
  printf "*Updated Add-ons* \n"

  # list Add-ons
  # shellcheck disable=SC2034  # addon: kept for readability, unused in loop body
  while IFS="/" read -r project platform addon filename; do
    if [[ ${project_rsync} != ${project}${platform} ]]; then
      # some crap due the slack function escape text
      printf '%s %s %s' "\n*${project}" "${platform}" "(${REPO_VERSION}) *\n"
      printf ' %s' "${filename%.*}\n"
    else
      printf ' %s' "${filename%.*}\n"
    fi
    project_rsync=${project}${platform}
  done < "${PATH_LOG}"
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

# check if jenkins addons are available
if [ ! -d "${PATH_STAGING}" ]; then
  slack "*WARNING*: no jenkins addons folder exist"
  exit 0;
fi

# exit cleanly if no add-on zips are staged
compgen -G "${PATH_STAGING}*.zip" > /dev/null 2>&1 || exit 0

# preparing folder
mkdir -p "${PATH_TARGET}" "${PATH_ADDON_REPO}"

# check for enough free disk space
if [[ $(df "${PATH_ADDON_REPO}" | awk 'END {print $4}') -lt 6000000 ]]; then
  slack "*WARNING*: not enough storage is available\n\`\`\`$(df "${PATH_ADDON_REPO}")\`\`\`"
  exit 0;
fi

# kill log
if [ -f "${PATH_LOG}" ]; then
  rm -f "${PATH_LOG}"
fi

touch "${PATH_LOG}"

# create target dir
mkdir -p "${PATH_TARGET}"

# check for sha256sum
for PROJECT in "${PATH_STAGING}"/*.zip; do
  cd "${PATH_STAGING}" || exit
    if sha256sum --status -c "${PROJECT}.sha256" 2>&1; then
      continue;
    else
      # remove files that fail at checksum test
      mv "${PROJECT}" "${PROJECT}"-ohohhhhh
      slack "*WARNING:* ${PROJECT##*/} wrong checksum \n"
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

# post to slack
if [ -s "${PATH_LOG}" ]; then
  slack "$(rsync_log)"
fi

exit 0
