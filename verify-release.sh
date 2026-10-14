#!/bin/sh
# verify-release.sh - check that the bytes a stranger downloads are the bytes this
# repository and its README describe.
#
# This repository exists to hand someone an APK that matches the claims beside it:
# README.md publishes the version, the size and the full SHA-256, the GitHub release
# carries the same asset with its own digest, and the release notes repeat the hash.
# Nothing verified that until now. This downloads the published asset and compares
# all of it, plus the copy committed here.
#
#   sh verify-release.sh              # check the latest published release
#   sh verify-release.sh v1.3         # check a specific tag
#
# Needs curl. Uses python3 for the API JSON and aapt2 for the APK's own version when
# they are available; without them it says so and checks what it can.
set -u

ROOT=$(cd "$(dirname "$0")" && pwd)
REPO_SLUG="kevinelong/score-android"
README="$ROOT/README.md"
COMMITTED="$ROOT/score-release.apk"
TAG=${1:-}
AAPT2="${SCORE_AAPT2:-$ROOT/../score/toolchain/sdk/build-tools/34.0.0/aapt2.exe}"

FAILS=0
ok()   { printf 'ok    %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }
same() { if [ "$2" = "$3" ]; then ok "$1: $3"; else bad "$1: documented '$2', actual '$3'"; fi; }
note() { printf '      %s\n' "$1"; }

# GNU sha256sum prefixes a backslash when the name it sees contains one, which is what
# an absolute Windows path looks like to it.
sha256() { sha256sum "$1" | cut -d' ' -f1 | tr -d '\\'; }
size()   { wc -c < "$1" | tr -d ' \r'; }

win() { # a path curl.exe can use
    if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

command -v curl >/dev/null 2>&1 || { echo "verify-release.sh needs curl" >&2; exit 1; }

# ------------------------------------------------------------- what the README says
doc_version=$(grep -E '^\| Version \|' "$README" | sed -n 's/.*| \([0-9][0-9.]*\) (versionCode \([0-9]*\)).*/\1/p')
doc_code=$(grep -E '^\| Version \|' "$README" | sed -n 's/.*versionCode \([0-9]*\).*/\1/p')
doc_size=$(grep -E '^\| Size \|' "$README" | sed -n 's/.*| \([0-9][0-9,]*\) bytes.*/\1/p' | tr -d ',')
doc_hash=$(grep -E '^\| SHA-256 \|' "$README" | sed -n 's/.*`\([0-9a-f]*\)`.*/\1/p')
[ -n "$doc_version" ] && [ -n "$doc_hash" ] || { echo "cannot read the claims from $README" >&2; exit 1; }
note "README claims: version $doc_version (versionCode $doc_code), $doc_size bytes, $doc_hash"

# --------------------------------------------------------------- what the API serves
API="https://api.github.com/repos/$REPO_SLUG/releases/latest"
[ -n "$TAG" ] && API="https://api.github.com/repos/$REPO_SLUG/releases/tags/$TAG"
json=$(curl -sS -H 'Accept: application/vnd.github+json' "$API" 2>/dev/null || true)
[ -n "$json" ] || { echo "could not read $API" >&2; exit 1; }

fields=$(printf '%s' "$json" | python3 -c '
import json, sys
d = json.load(sys.stdin)
a = next((x for x in (d.get("assets") or []) if x.get("name") == "score-release.apk"), {})
notes = ""
for ln in (d.get("body") or "").splitlines():
    if "SHA-256 of score-release.apk:" in ln:
        notes = ln.split(":")[-1].strip()
url = a.get("browser_download_url") or ""
print(d.get("tag_name", ""))
print(a.get("size", ""))
print((a.get("digest") or "").removeprefix("sha256:"))
print(notes)
print(url)
')
tag=$(printf '%s\n' "$fields" | sed -n 1p)
asset_size=$(printf '%s\n' "$fields" | sed -n 2p)
asset_digest=$(printf '%s\n' "$fields" | sed -n 3p)
notes_hash=$(printf '%s\n' "$fields" | sed -n 4p)
asset_url=$(printf '%s\n' "$fields" | sed -n 5p)
[ -n "$asset_url" ] || { echo "release ${TAG:-latest} carries no score-release.apk" >&2; exit 1; }
note "release $tag: asset $asset_size bytes, digest $asset_digest"

same "tag vs the README's version" "v$doc_version" "$tag"
same "asset size vs the README" "$doc_size" "$asset_size"
same "asset digest vs the README" "$doc_hash" "$asset_digest"
same "release notes' hash vs the README" "$doc_hash" "$notes_hash"

# ----------------------------------------------------- the bytes a stranger downloads
tmp=$(mktemp 2>/dev/null || echo "./verify-release.$$.tmp")
trap 'rm -f "$tmp"' EXIT
curl -fsSL -o "$(win "$tmp")" "$asset_url" || { bad "could not download $asset_url"; exit 1; }
got_hash=$(sha256 "$tmp")
got_size=$(size "$tmp")
same "downloaded size vs the README" "$doc_size" "$got_size"
same "downloaded sha256 vs the README" "$doc_hash" "$got_hash"
same "downloaded sha256 vs the release digest" "$asset_digest" "$got_hash"

# ------------------------------------------------- and the copy committed right here
if [ -f "$COMMITTED" ]; then
    same "committed score-release.apk sha256" "$doc_hash" "$(sha256 "$COMMITTED")"
    same "committed score-release.apk size" "$doc_size" "$(size "$COMMITTED")"
else
    note "no score-release.apk committed here - skipping"
fi

# ------------------------------------------- and the version inside the APK itself
if [ -x "$AAPT2" ]; then
    dump=$("$AAPT2" dump badging "$(win "$tmp")" 2>/dev/null || true)
    vn=$(printf '%s\n' "$dump" | sed -n "s/^package: .*versionName='\([^']*\)'.*/\1/p")
    vc=$(printf '%s\n' "$dump" | sed -n "s/^package: .*versionCode='\([0-9]*\)'.*/\1/p")
    pkg=$(printf '%s\n' "$dump" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")
    same "the APK's own versionName vs the README" "$doc_version" "$vn"
    same "the APK's own versionCode vs the README" "$doc_code" "$vc"
    same "the APK's package name" "com.kevin.score" "$pkg"
else
    note "no aapt2 at $AAPT2 - the APK's own version was not read"
fi

echo
if [ "$FAILS" = 0 ]; then
    echo "the published bytes match every claim"
else
    echo "$FAILS claim(s) do not match the published bytes"
    exit 1
fi
