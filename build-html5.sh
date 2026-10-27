#!/usr/bin/env bash
# Builds the HTML5 version with the Solar2D Linux snap (see README.md, "Building for the web").
#
# The snap can only see $HOME, and its console builder has no HTML5 support on Linux,
# so the project is staged under $HOME and built through the simulator GUI:
#   File -> Build -> HTML5, then close the simulator; the result is copied into builds/.
#
#   ./build-html5.sh        build into builds/ddos-is-coming.html5
#   ./build-html5.sh serve  build, then serve it on http://localhost:8000
set -euo pipefail
cd "$(dirname "$0")"

name=ddos-is-coming
stage="$HOME/ld46-html5"
out="builds/$name.html5"

mkdir -p "$stage/src" "$stage/out"
rsync -a --delete \
    --exclude .git --exclude .idea --exclude builds --exclude screenshots --exclude build-html5.sh \
    ./ "$stage/src/"
rm -rf "$stage/out/$name.html5"

cat <<MSG
Solar2D simulator is starting; the project opens as a running game, that is expected.
In the game window press Ctrl+Alt+B (File -> Build -> HTML5...):
    Application Name: $name
    Version Code:     2020.04.18
    Save To Folder:   $stage/out
  Build, wait for "Your application was built successfully", then quit with Ctrl+Q.
MSG
solar2d "$stage/src/main.lua"

test -f "$stage/out/$name.html5/index.html"
mkdir -p builds
rm -rf "$out"
cp -r "$stage/out/$name.html5" "$out"
echo "→ $out"

if [[ "${1:-}" == "serve" ]]; then
    python3 -m http.server -d "$out" 8000
fi
