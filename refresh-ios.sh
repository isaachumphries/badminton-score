#!/usr/bin/env bash
# Re-sign and install the latest CI release build. Free Apple ID signing expires after 7 days; rerun this (phone plugged in).
set -e
d=$(mktemp -d)
gh run download "$(gh run list --workflow=ios.yml --status success --limit 1 --json databaseId -q '.[0].databaseId')" -n badminton-ipa -D "$d"
xtool install "$d/badminton.ipa"
rm -rf "$d"
