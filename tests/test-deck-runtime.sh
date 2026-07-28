#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/core/scripts/deck-runtime.sh"
SOURCE="$ROOT/core/DeckUI"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

snapshot() {
  python3 - "$1" <<'PY'
import hashlib
import os
import stat
import sys
from pathlib import Path

root = Path(sys.argv[1])
digest = hashlib.sha256()
for path in sorted(root.rglob("*")):
    relative = path.relative_to(root).as_posix()
    mode = path.lstat().st_mode
    digest.update(relative.encode() + b"\0" + str(stat.S_IMODE(mode)).encode() + b"\0")
    if stat.S_ISLNK(mode):
        digest.update(b"L\0" + os.fsencode(os.readlink(path)) + b"\0")
    elif stat.S_ISDIR(mode):
        digest.update(b"D\0")
    elif stat.S_ISREG(mode):
        digest.update(b"F\0" + path.read_bytes() + b"\0")
    else:
        digest.update(b"O\0")
print(digest.hexdigest())
PY
}

before="$(snapshot "$SOURCE")"
cache_base="$TMP/cache"

# Read-only discovery does not initialize mutable runtime state.
SCV_DECK_CACHE_DIR="$TMP/help-cache" bash "$ROOT/core/scripts/deck.sh" --help \
  >/dev/null
[[ ! -e "$TMP/help-cache" ]]
path_only="$(
  SCV_DECK_CACHE_DIR="$TMP/path-cache" bash "$HELPER" path
)"
[[ "$path_only" == "$TMP/path-cache"/*/DeckUI ]]
[[ ! -e "$TMP/path-cache" ]]

runtime="$(
  SCV_DECK_CACHE_DIR="$cache_base" bash "$HELPER" ensure
)"
[[ -d "$runtime" && -f "$runtime/.scv-deck-runtime.json" ]]
[[ "$runtime" == "$cache_base"/*/DeckUI ]]
[[ ! -e "$runtime/node_modules" ]]
[[ ! -e "$runtime/scripts/deckdoc/node_modules" ]]
[[ ! -e "$runtime/dist-deck" ]]
[[ "$before" == "$(snapshot "$SOURCE")" ]]

again="$(
  SCV_DECK_CACHE_DIR="$cache_base" bash "$HELPER" ensure
)"
[[ "$again" == "$runtime" ]]

# Two first-use initializers converge on one atomic cache tree.
parallel_base="$TMP/parallel"
SCV_DECK_CACHE_DIR="$parallel_base" bash "$HELPER" ensure > "$TMP/one.out" &
pid_one=$!
SCV_DECK_CACHE_DIR="$parallel_base" bash "$HELPER" ensure > "$TMP/two.out" &
pid_two=$!
wait "$pid_one"
wait "$pid_two"
cmp "$TMP/one.out" "$TMP/two.out"
[[ -f "$(cat "$TMP/one.out")/.scv-deck-runtime.json" ]]

# Legacy runtime migration preserves pnpm-style links and generated decks.
legacy="$TMP/legacy"
mkdir -p \
  "$legacy/node_modules/.pnpm/pkg/node_modules/pkg" \
  "$legacy/scripts/deckdoc/node_modules" \
  "$legacy/dist-deck" \
  "$legacy/src/deck/decks/generated"
printf 'module\n' > "$legacy/node_modules/.pnpm/pkg/node_modules/pkg/index.js"
ln -s .pnpm/pkg/node_modules/pkg "$legacy/node_modules/pkg"
printf 'deckdoc\n' > "$legacy/scripts/deckdoc/node_modules/sentinel"
printf 'built\n' > "$legacy/dist-deck/index.html"
printf '{"generated":true}\n' > "$legacy/src/deck/decks/generated/deck.json"

migrated="$(
  SCV_DECK_CACHE_DIR="$cache_base" \
    bash "$HELPER" migrate --from "$legacy"
)"
[[ "$migrated" == "$runtime" ]]
[[ -L "$runtime/node_modules/pkg" ]]
[[ "$(readlink "$runtime/node_modules/pkg")" == ".pnpm/pkg/node_modules/pkg" ]]
cmp \
  "$legacy/scripts/deckdoc/node_modules/sentinel" \
  "$runtime/scripts/deckdoc/node_modules/sentinel"
cmp "$legacy/dist-deck/index.html" "$runtime/dist-deck/index.html"
cmp \
  "$legacy/src/deck/decks/generated/deck.json" \
  "$runtime/src/deck/decks/generated/deck.json"

# Migration is idempotent, but a different destination never gets overwritten.
SCV_DECK_CACHE_DIR="$cache_base" \
  bash "$HELPER" migrate --from "$legacy" >/dev/null
printf '{"different":true}\n' > "$runtime/src/deck/decks/generated/deck.json"
if SCV_DECK_CACHE_DIR="$cache_base" \
    bash "$HELPER" migrate --from "$legacy" >/dev/null 2>&1; then
  echo "runtime collision was overwritten" >&2
  exit 1
fi
grep -q '"different":true' "$runtime/src/deck/decks/generated/deck.json"

# Generated Deck links are never followed out of the legacy runtime.
unsafe_legacy="$TMP/unsafe-legacy"
mkdir -p "$unsafe_legacy/src/deck/decks"
ln -s "$TMP" "$unsafe_legacy/src/deck/decks/escaped"
if SCV_DECK_CACHE_DIR="$cache_base" \
    bash "$HELPER" migrate --from "$unsafe_legacy" >/dev/null 2>&1; then
  echo "legacy generated Deck directory symlink was accepted" >&2
  exit 1
fi

# Unsafe cache locations and a symlink runtime target fail before mutation.
if SCV_DECK_CACHE_DIR="$SOURCE/cache" \
    bash "$HELPER" ensure >/dev/null 2>&1; then
  echo "cache under immutable source was accepted" >&2
  exit 1
fi
[[ ! -e "$SOURCE/cache" ]]

symlink_base="$TMP/symlink-cache"
target_path="$(
  SCV_DECK_CACHE_DIR="$symlink_base" bash "$HELPER" path
)"
mkdir -p "$(dirname "$target_path")" "$TMP/outside"
ln -s "$TMP/outside" "$target_path"
if SCV_DECK_CACHE_DIR="$symlink_base" \
    bash "$HELPER" ensure >/dev/null 2>&1; then
  echo "symlink runtime target was accepted" >&2
  exit 1
fi
[[ -z "$(find "$TMP/outside" -mindepth 1 -print -quit)" ]]

# A source checkout with a non-runtime link is rejected rather than copied.
unsafe_core="$TMP/unsafe-core"
mkdir -p "$unsafe_core/scripts" "$unsafe_core/DeckUI/source"
cp "$HELPER" "$unsafe_core/scripts/deck-runtime.sh"
printf 'outside\n' > "$TMP/outside-file"
ln -s "$TMP/outside-file" "$unsafe_core/DeckUI/source/escape"
if SCV_DECK_CACHE_DIR="$TMP/unsafe-source-cache" \
    bash "$unsafe_core/scripts/deck-runtime.sh" ensure >/dev/null 2>&1; then
  echo "immutable DeckUI source link was accepted" >&2
  exit 1
fi

# Materialized wrappers share the canonical source-payload key and fail closed
# instead of silently falling back when their integrity lock is malformed.
locked_root="$TMP/locked"
mkdir -p "$locked_root/core/scripts" "$locked_root/core/DeckUI"
cp "$HELPER" "$locked_root/core/scripts/deck-runtime.sh"
printf 'source\n' > "$locked_root/core/DeckUI/source.txt"
lock_key='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
printf '{"source_payload_sha256":"%s"}\n' "$lock_key" \
  > "$locked_root/core.lock.json"
locked_path="$(
  SCV_DECK_CACHE_DIR="$TMP/locked-cache" \
    bash "$locked_root/core/scripts/deck-runtime.sh" path
)"
[[ "$locked_path" == "$TMP/locked-cache/$lock_key/DeckUI" ]]
printf '{broken\n' > "$locked_root/core.lock.json"
if SCV_DECK_CACHE_DIR="$TMP/locked-cache" \
    bash "$locked_root/core/scripts/deck-runtime.sh" ensure >/dev/null 2>&1; then
  echo "malformed Core lock fell back to a source hash" >&2
  exit 1
fi

[[ "$before" == "$(snapshot "$SOURCE")" ]]
grep -q 'DECK_RUNTIME=.*deck-runtime.sh' "$ROOT/core/scripts/deck.sh"
grep -q 'DECKUI=.*DECK_RUNTIME.*ensure' "$ROOT/core/scripts/deck.sh"

echo "external DeckUI runtime cache and migration: ok"
