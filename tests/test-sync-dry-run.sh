#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HYDRATE="$ROOT/core/scripts/hydrate.sh"
SYNC="$ROOT/core/scripts/sync.sh"
PROFILE="$ROOT/tests/fixtures/claude-code.env"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

snapshot() {
  local project="$1"
  (
    cd "$project"
    find . -mindepth 1 -print | LC_ALL=C sort
    while IFS= read -r file; do cksum "$file"; done \
      < <(find . -type f | LC_ALL=C sort)
  )
}

PROJECT="$TMP/project"
bash "$HYDRATE" init "$PROJECT" >/dev/null
BEFORE="$(snapshot "$PROJECT")"
OUTPUT="$(
  SCV_HOST_PROFILE="$PROFILE" bash "$SYNC" \
    --project-dir "$PROJECT" \
    --dry-run \
    --join git@github.com:example/root.git \
    --id api \
    --role backend \
    --workspace example
)"
AFTER="$(snapshot "$PROJECT")"
[[ "$BEFORE" == "$AFTER" ]]
grep -qF 'JOIN      scv/SCV.md (workspace block)' <<< "$OUTPUT"
grep -qF '(dry-run mode — no files modified)' <<< "$OUTPUT"
if grep -qF 'root: git@github.com:example/root.git' "$PROJECT/scv/SCV.md"; then
  echo "dry-run join changed SCV.md" >&2
  exit 1
fi

SCV_HOST_PROFILE="$PROFILE" bash "$SYNC" \
  --project-dir "$PROJECT" \
  --join git@github.com:example/root.git \
  --id api \
  --role backend \
  --workspace example >/dev/null
grep -qF 'root: git@github.com:example/root.git' "$PROJECT/scv/SCV.md"

LEGACY="$TMP/legacy"
bash "$HYDRATE" init "$LEGACY" >/dev/null
mv "$LEGACY/scv/SCV.md" "$LEGACY/scv/CLAUDE.md"
BEFORE="$(snapshot "$LEGACY")"
OUTPUT="$(
  SCV_HOST_PROFILE="$PROFILE" bash "$SYNC" \
    --project-dir "$LEGACY" \
    --dry-run \
    --join ../umbrella \
    --id legacy
)"
AFTER="$(snapshot "$LEGACY")"
[[ "$BEFORE" == "$AFTER" ]]
[[ ! -e "$LEGACY/scv/SCV.md" ]]
grep -qF 'MIGRATE   scv/CLAUDE.md → scv/SCV.md' <<< "$OUTPUT"
grep -qF 'JOIN      scv/SCV.md (workspace block)' <<< "$OUTPUT"

for missing_value_flag in --project-dir --force --join --id --role --workspace; do
  set +e
  bash "$SYNC" "$missing_value_flag" >/dev/null 2>&1
  rc=$?
  set -e
  [[ $rc -eq 2 ]] || {
    echo "$missing_value_flag without value: expected rc=2, got $rc" >&2
    exit 1
  }
done

echo "sync join dry-run and argument errors: ok"
