#!/bin/bash

# abort at error
set -e

# create changelog
generate_changelog() {
  # html header
  cat <<EOF
<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" href="https://test.libreelec.tv/css/listing.css"/>
</head>
<body>
<h2> Changelog</h2>
<table class="changelogTable" style="width: 100%;">
<tbody>
EOF

  # get commits from GH API
  gh_output="$(curl -sH "Accept: application/vnd.github.v3+json" https://api.github.com/repos/LibreELEC/LibreELEC.tv/commits?per_page=60 | jq '.[] | "\(.commit.author.date | .[0:10]) \(.sha | .[0:7]) \(.commit.message)"' | grep "Merge pull request")"

  while IFS= read -r line; do
    # PR link
    var_pr="$(grep -oE '#[0-9]+' <<<"$line")"

    # PR message
    var_message="$(grep -oP '(?<=\\n\\n)(.*)(?=\")' <<<"$line" || true)"

    # PR date at merge
    var_date="$(grep -oP '(?<=^")[0-9-]{10}' <<<"$line")"

    # git shorthash
    var_hash="$(grep -oP '(?<=^"[0-9-]{10} )[0-9a-f]{7}' <<<"$line")"

    # output line
    echo "<tr><td>$var_date ($var_hash):</td><td><a href=\"https://github.com/LibreELEC/LibreELEC.tv/pull/${var_pr//#/}\" target="_blank" rel="noopener noreferrer">${var_pr}</a></td><td>${var_message}</td></tr>"
  done <<<"$gh_output"

  # html footer
  cat <<EOF
</tbody>
</table>
</body>
</html>
EOF
}

# generate and output to file
generate_changelog >/var/www/test/css/changelog.html
