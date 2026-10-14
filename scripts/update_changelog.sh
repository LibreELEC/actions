#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

# abort on unhandled error
set -e

# Output destination (defaults to /var/www/test/fonts/changelog.json, or optional $1 CLI argument)
OUTPUT_FILE="${1:-/var/www/test/fonts/changelog.json}"
TMP_FILE="${OUTPUT_FILE}.tmp"

# Clean up temporary file on exit
trap 'rm -f "${TMP_FILE}"' EXIT

# GitHub API Headers (supports optional GITHUB_TOKEN for higher rate limits)
CURL_ARGS=(-sS --fail --max-time 15 -H "Accept: application/vnd.github.v3+json")
if [ -n "${GITHUB_TOKEN:-}" ]; then
  CURL_ARGS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

# 1. Fetch commits from GitHub API
if ! raw_response="$(curl "${CURL_ARGS[@]}" "https://api.github.com/repos/LibreELEC/LibreELEC.tv/commits?per_page=60" 2>/dev/null)"; then
  echo "Error: Could not connect to GitHub API or received HTTP error. Existing changelog unchanged." >&2
  exit 1
fi

# 2. Verify response is valid JSON and an array of commits
if ! echo "${raw_response}" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
  echo "Error: Response from GitHub API is not a valid commit array. Existing changelog unchanged." >&2
  exit 1
fi

# 3. Transform commits into changelog JSON structure
if ! parsed_json="$(echo "${raw_response}" | jq -e '{
  title: "Changelog",
  entries: [
    .[]
    | select(.commit.message | test("Merge pull request #[0-9]+"))
    | {
        date: .commit.author.date[0:10],
        commit: .sha[0:7],
        pull_request: (.commit.message | capture("Merge pull request #(?<pr>[0-9]+)").pr | tonumber),
        url: ("https://github.com/LibreELEC/LibreELEC.tv/pull/" + (.commit.message | capture("Merge pull request #(?<pr>[0-9]+)").pr)),
        description: (.commit.message | split("\n\n") | if length > 1 then (.[1] | split("\n") | .[0] | rtrimstr("\r")) else "" end)
      }
  ]
}' 2>/dev/null)"; then
  echo "Error: Failed to process commits into changelog format. Existing changelog unchanged." >&2
  exit 1
fi

# 4. Verify parsed JSON is valid and contains entries
if ! echo "${parsed_json}" | jq -e '.entries | type == "array" and length > 0' >/dev/null 2>&1; then
  echo "Error: Parsed changelog contains no valid entries. Existing changelog unchanged." >&2
  exit 1
fi

# 5. Write output
echo "${parsed_json}" >"${TMP_FILE}"
mv "${TMP_FILE}" "${OUTPUT_FILE}"
