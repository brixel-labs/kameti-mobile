#!/bin/sh
# Copies a Flutter env file into the native app's gitignored config, so the
# native app uses the same Supabase project and Google client IDs.
#
#   native/ios/scripts/use-env.sh dev    # local Supabase (127.0.0.1:55421)
#   native/ios/scripts/use-env.sh prod   # kameti-prod
#
# Then build the app again. The file is bundled at build time.
set -eu
flavor="${1:-}"
case "$flavor" in dev|prod|staging) ;; *) echo "usage: use-env.sh dev|prod|staging" >&2; exit 2 ;; esac
root="$(cd "$(dirname "$0")/../../.." && pwd)"
source="$root/env/$flavor.json"
target="$root/native/ios/Kameti/Kameti/KametiConfig.json"
[ -f "$source" ] || { echo "missing $source (copy env/example.json and fill it in)" >&2; exit 1; }
cp "$source" "$target"
echo "native app now uses env/$flavor.json"
