#!/bin/sh
# Copies env/<flavor>.json into the Android app's gitignored config (Supabase
# project and Google client IDs). Same files as ios/scripts/use-env.sh.
#
#   android/scripts/use-env.sh dev    # local Supabase
#   android/scripts/use-env.sh prod   # kameti-prod
#   android/scripts/use-env.sh demo   # sample kametis, no backend, already signed in
#
# Then build the app again. The file is bundled at build time.
set -eu
flavor="${1:-}"
case "$flavor" in dev|prod|staging|demo) ;; *) echo "usage: use-env.sh dev|prod|staging|demo" >&2; exit 2 ;; esac
root="$(cd "$(dirname "$0")/../.." && pwd)"
target="$root/android/app/src/main/assets/KametiConfig.json"
mkdir -p "$(dirname "$target")"
if [ "$flavor" = demo ]; then
  printf '{"FLAVOR":"demo","SUPABASE_URL":"http://localhost","SUPABASE_PUBLISHABLE_KEY":"demo"}\n' > "$target"
  echo "Android app now runs on sample data (no backend)"
  exit 0
fi
source="$root/env/$flavor.json"
[ -f "$source" ] || { echo "missing $source (copy env/example.json and fill it in)" >&2; exit 1; }
cp "$source" "$target"
echo "Android app now uses env/$flavor.json"
