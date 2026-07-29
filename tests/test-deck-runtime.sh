#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/core/scripts/deck-runtime.sh"
SOURCE="$ROOT/core/DeckUI"
TMP="$(mktemp -d)"
TMP="$(cd "$TMP" && pwd -P)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; rm -rf "$TMP"' EXIT

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

wait_for_pause() {
  local ready_file="$1"
  local process_id="$2"
  local error_file="$3"
  local label="$4"
  local _
  for _ in $(seq 1 1500); do
    if [[ -s "$ready_file" ]]; then
      return 0
    fi
    if ! kill -0 "$process_id" 2>/dev/null; then
      wait "$process_id" 2>/dev/null || true
      echo "$label did not reach its deterministic pause" >&2
      sed -n '1,120p' "$error_file" >&2
      return 1
    fi
    sleep 0.01
  done
  echo "$label timed out waiting for its deterministic pause" >&2
  return 1
}

expect_paused_failure() {
  local process_id="$1"
  local continue_file="$2"
  local label="$3"
  : >"$continue_file"
  if wait "$process_id"; then
    echo "$label unexpectedly succeeded" >&2
    return 1
  fi
}

expect_usage_without_cache() {
  local cache_base="$1"
  shift
  set +e
  SCV_DECK_CACHE_DIR="$cache_base" \
    bash "$HELPER" "$@" >/dev/null 2>&1
  local usage_rc=$?
  set -e
  [[ "$usage_rc" -eq 2 ]]
  [[ ! -e "$cache_base" ]]
}

prepare_reuse_collision() {
  local fixture_base="$1"
  local authoritative_source="$2"
  local conflicting_source="$3"
  mkdir -p \
    "$authoritative_source/node_modules/pkg" \
    "$conflicting_source/node_modules/pkg"
  printf 'authoritative\n' \
    >"$authoritative_source/node_modules/pkg/index.js"
  printf 'conflicting\n' \
    >"$conflicting_source/node_modules/pkg/index.js"
  SCV_DECK_CACHE_DIR="$fixture_base" \
    bash "$HELPER" migrate --from "$authoritative_source" >/dev/null
}

assert_no_runtime_debris() {
  local fixture_base="$1"
  [[ -z "$(
    find "$fixture_base" \
      \( \
        -name '.*.lock' -o \
        -name '.*.lock.new-*' -o \
        -name '.*.stage-*' -o \
        -name '.*.install-*' \
      \) -print -quit
  )" ]]
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

# The opt-in flag has one strict, final-position grammar and is rejected before
# any cache directory can be created.
invalid_flag_legacy="$TMP/invalid-flag-legacy"
mkdir -p "$invalid_flag_legacy"
expect_usage_without_cache \
  "$TMP/invalid-flag-order-cache" \
  migrate --reuse-existing --from "$invalid_flag_legacy"
expect_usage_without_cache \
  "$TMP/invalid-flag-duplicate-cache" \
  migrate --from "$invalid_flag_legacy" \
  --reuse-existing --reuse-existing
expect_usage_without_cache \
  "$TMP/invalid-flag-command-cache" \
  ensure --reuse-existing

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

# A contender that observed an ordinary lock just before its owner releases it
# retries the normal handoff instead of treating open(ENOENT) as corruption.
handoff_base="$TMP/handoff-cache"
handoff_a_ready="$TMP/handoff-a.ready"
handoff_a_continue="$TMP/handoff-a.continue"
handoff_b_ready="$TMP/handoff-b.ready"
handoff_b_continue="$TMP/handoff-b.continue"
SCV_DECK_CACHE_DIR="$handoff_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=locked-before-operation \
SCV_DECK_RUNTIME_TEST_READY_FILE="$handoff_a_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$handoff_a_continue" \
  bash "$HELPER" ensure >"$TMP/handoff-a.out" \
  2>"$TMP/handoff-a.err" &
handoff_a_pid=$!
wait_for_pause \
  "$handoff_a_ready" "$handoff_a_pid" "$TMP/handoff-a.err" \
  "first lock-handoff contender"
SCV_DECK_CACHE_DIR="$handoff_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=lock-before-open \
SCV_DECK_RUNTIME_TEST_READY_FILE="$handoff_b_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$handoff_b_continue" \
  bash "$HELPER" ensure >"$TMP/handoff-b.out" \
  2>"$TMP/handoff-b.err" &
handoff_b_pid=$!
wait_for_pause \
  "$handoff_b_ready" "$handoff_b_pid" "$TMP/handoff-b.err" \
  "second lock-handoff contender"
: >"$handoff_a_continue"
wait "$handoff_a_pid"
: >"$handoff_b_continue"
wait "$handoff_b_pid"
cmp "$TMP/handoff-a.out" "$TMP/handoff-b.out"
[[ -f "$(cat "$TMP/handoff-a.out")/.scv-deck-runtime.json" ]]
[[ -z "$(
  find "$handoff_base" -maxdepth 1 \
    \( -name '.*.lock' -o -name '.*.lock.new-*' \) \
    -print -quit
)" ]]

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

# File modes are copied exactly even when the caller's umask is restrictive.
umask_base="$TMP/umask-cache"
umask_legacy="$TMP/umask-legacy"
mkdir -p "$umask_legacy/dist-deck"
printf 'umask\n' >"$umask_legacy/dist-deck/index.html"
chmod 0644 "$umask_legacy/dist-deck/index.html"
umask_legacy_before="$(snapshot "$umask_legacy")"
umask_runtime="$(
  umask 077
  SCV_DECK_CACHE_DIR="$umask_base" \
    bash "$HELPER" migrate --from "$umask_legacy"
)"
cmp \
  "$umask_legacy/dist-deck/index.html" \
  "$umask_runtime/dist-deck/index.html"
umask_modes="$(
  python3 - \
    "$umask_legacy/dist-deck/index.html" \
    "$umask_runtime/dist-deck/index.html" <<'PY'
import os
import stat
import sys

print(
    " ".join(
        str(stat.S_IMODE(os.lstat(path).st_mode))
        for path in sys.argv[1:]
    )
)
PY
)"
[[ "$umask_modes" == "420 420" ]]
[[ "$umask_legacy_before" == "$(snapshot "$umask_legacy")" ]]
[[ -z "$(
  find "$umask_base" -maxdepth 1 \
    \( -name '.*.lock' -o -name '.*.lock.new-*' \) \
    -print -quit
)" ]]

# setuid/setgid bits are applied after the payload write so the kernel cannot
# clear them as a side effect of copying file contents.
setid_base="$TMP/setid-cache"
setid_legacy="$TMP/setid-legacy"
mkdir -p "$setid_legacy/dist-deck"
printf '#!/bin/sh\nexit 0\n' >"$setid_legacy/dist-deck/tool"
chmod 04755 "$setid_legacy/dist-deck/tool"
setid_legacy_before="$(snapshot "$setid_legacy")"
setid_runtime="$(
  SCV_DECK_CACHE_DIR="$setid_base" \
    bash "$HELPER" migrate --from "$setid_legacy"
)"
cmp \
  "$setid_legacy/dist-deck/tool" \
  "$setid_runtime/dist-deck/tool"
setid_modes="$(
  python3 - \
    "$setid_legacy/dist-deck/tool" \
    "$setid_runtime/dist-deck/tool" <<'PY'
import os
import stat
import sys

print(
    " ".join(
        str(stat.S_IMODE(os.lstat(path).st_mode))
        for path in sys.argv[1:]
    )
)
PY
)"
[[ "$setid_modes" == "2541 2541" ]]
[[ "$setid_legacy_before" == "$(snapshot "$setid_legacy")" ]]
[[ -z "$(
  find "$setid_base" -maxdepth 1 \
    \( -name '.*.lock' -o -name '.*.lock.new-*' \) \
    -print -quit
)" ]]

# Read-only legacy directories remain readable during migration. Their children
# are populated through a private writable stage, then the source mode is
# restored on the completed destination without mutating the source.
readonly_base="$TMP/readonly-dir-cache"
readonly_legacy="$TMP/readonly-dir-legacy"
mkdir -p "$readonly_legacy/dist-deck"
printf 'readonly\n' >"$readonly_legacy/dist-deck/index.html"
chmod 0555 "$readonly_legacy/dist-deck"
readonly_legacy_before="$(snapshot "$readonly_legacy")"
readonly_runtime="$(
  SCV_DECK_CACHE_DIR="$readonly_base" \
    bash "$HELPER" migrate --from "$readonly_legacy"
)"
readonly_namespace="$(dirname "$readonly_runtime")"
cmp \
  "$readonly_legacy/dist-deck/index.html" \
  "$readonly_runtime/dist-deck/index.html"
readonly_modes="$(
  python3 - \
    "$readonly_legacy/dist-deck" \
    "$readonly_runtime/dist-deck" <<'PY'
import os
import stat
import sys

print(
    " ".join(
        str(stat.S_IMODE(os.lstat(path).st_mode))
        for path in sys.argv[1:]
    )
)
PY
)"
[[ "$readonly_modes" == "365 365" ]]
[[ "$readonly_legacy_before" == "$(snapshot "$readonly_legacy")" ]]
[[ -z "$(
  find "$readonly_base" -maxdepth 1 \
    \( -name '.*.lock' -o -name '.*.lock.new-*' \) \
    -print -quit
)" ]]
[[ -z "$(
  find "$readonly_namespace" -maxdepth 1 \
    -name '.dist-deck.stage-*' -print -quit
)" ]]
[[ -z "$(
  find "$readonly_runtime" -maxdepth 1 \
    -name '.dist-deck.install-*' -print -quit
)" ]]

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

# Opt-in reuse treats the first populated cache as authoritative. One differing
# pre-existing entry skips this legacy source as a whole: equal and missing
# entries are not mixed into the cache, while stdout remains the target path.
reuse_notice='NOTICE: existing Deck runtime cache differs; reusing it as authoritative and skipping this legacy migration'
reuse_base="$TMP/reuse-cache"
reuse_authoritative="$TMP/reuse-authoritative"
mkdir -p "$reuse_authoritative/node_modules/pkg"
printf 'authoritative\n' \
  >"$reuse_authoritative/node_modules/pkg/index.js"
chmod 0755 \
  "$reuse_authoritative/node_modules" \
  "$reuse_authoritative/node_modules/pkg"
reuse_runtime="$(
  SCV_DECK_CACHE_DIR="$reuse_base" \
    bash "$HELPER" migrate --from "$reuse_authoritative"
)"
reuse_legacy="$TMP/reuse-legacy"
mkdir -p \
  "$reuse_legacy/node_modules/pkg" \
  "$reuse_legacy/dist-deck" \
  "$reuse_legacy/src/deck/decks/unique-host-b"
printf 'different-host\n' >"$reuse_legacy/node_modules/pkg/index.js"
printf 'host-b-build\n' >"$reuse_legacy/dist-deck/index.html"
printf '{"host":"b"}\n' \
  >"$reuse_legacy/src/deck/decks/unique-host-b/deck.json"
reuse_source_before="$(snapshot "$reuse_legacy")"
reuse_cache_before="$(snapshot "$reuse_base")"
reuse_stdout="$(
  SCV_DECK_CACHE_DIR="$reuse_base" \
    bash "$HELPER" migrate --from "$reuse_legacy" --reuse-existing \
    2>"$TMP/reuse.err"
)"
[[ "$reuse_stdout" == "$reuse_runtime" ]]
[[ "$(cat "$TMP/reuse.err")" == "$reuse_notice" ]]
[[ "$reuse_cache_before" == "$(snapshot "$reuse_base")" ]]
[[ "$reuse_source_before" == "$(snapshot "$reuse_legacy")" ]]
grep -q 'authoritative' "$reuse_runtime/node_modules/pkg/index.js"
[[ ! -e "$reuse_runtime/dist-deck" ]]
[[ \
  ! -e \
  "$reuse_runtime/src/deck/decks/unique-host-b/deck.json" \
]]
[[ -z "$(
  find "$reuse_base" \
    \( \
      -name '.*.lock' -o \
      -name '.*.lock.new-*' -o \
      -name '.*.stage-*' -o \
      -name '.*.install-*' \
    \) -print -quit
)" ]]

# Repeating the opt-in decision is idempotent and emits one stable notice.
reuse_repeat_stdout="$(
  SCV_DECK_CACHE_DIR="$reuse_base" \
    bash "$HELPER" migrate --from "$reuse_legacy" --reuse-existing \
    2>"$TMP/reuse-repeat.err"
)"
[[ "$reuse_repeat_stdout" == "$reuse_runtime" ]]
[[ "$(cat "$TMP/reuse-repeat.err")" == "$reuse_notice" ]]
[[ "$reuse_cache_before" == "$(snapshot "$reuse_base")" ]]
[[ "$reuse_source_before" == "$(snapshot "$reuse_legacy")" ]]

# Directory modes participate in collision digests at both the root and nested
# levels, even when every file byte is equal.
mode_digest_base="$TMP/mode-digest-cache"
mode_digest_authoritative="$TMP/mode-digest-authoritative"
mkdir -p "$mode_digest_authoritative/dist-deck/nested"
printf 'same\n' >"$mode_digest_authoritative/dist-deck/nested/index.html"
chmod 0755 \
  "$mode_digest_authoritative/dist-deck" \
  "$mode_digest_authoritative/dist-deck/nested"
mode_digest_runtime="$(
  SCV_DECK_CACHE_DIR="$mode_digest_base" \
    bash "$HELPER" migrate --from "$mode_digest_authoritative"
)"
mode_digest_legacy="$TMP/mode-digest-legacy"
mkdir -p "$mode_digest_legacy/dist-deck/nested"
printf 'same\n' >"$mode_digest_legacy/dist-deck/nested/index.html"
chmod 0700 "$mode_digest_legacy/dist-deck"
chmod 0755 "$mode_digest_legacy/dist-deck/nested"
if SCV_DECK_CACHE_DIR="$mode_digest_base" \
    bash "$HELPER" migrate --from "$mode_digest_legacy" \
    >/dev/null 2>"$TMP/mode-root-collision.err"; then
  echo "root directory mode collision was accepted" >&2
  exit 1
fi
grep -q 'migration collision' "$TMP/mode-root-collision.err"
chmod 0755 "$mode_digest_legacy/dist-deck"
chmod 0700 "$mode_digest_legacy/dist-deck/nested"
if SCV_DECK_CACHE_DIR="$mode_digest_base" \
    bash "$HELPER" migrate --from "$mode_digest_legacy" \
    >/dev/null 2>"$TMP/mode-child-collision.err"; then
  echo "nested directory mode collision was accepted" >&2
  exit 1
fi
grep -q 'migration collision' "$TMP/mode-child-collision.err"
grep -q 'same' "$mode_digest_runtime/dist-deck/nested/index.html"

# Digest records length-frame arbitrary payload bytes. A single file whose
# payload reproduces the old serialization of a following file cannot collide
# with a structurally different two-file tree.
framing_base="$TMP/digest-framing-cache"
framing_authoritative="$TMP/digest-framing-authoritative"
mkdir -p "$framing_authoritative/dist-deck"
: >"$framing_authoritative/dist-deck/a"
printf 'x' >"$framing_authoritative/dist-deck/b"
chmod 0755 "$framing_authoritative/dist-deck"
chmod 0644 \
  "$framing_authoritative/dist-deck/a" \
  "$framing_authoritative/dist-deck/b"
framing_runtime="$(
  SCV_DECK_CACHE_DIR="$framing_base" \
    bash "$HELPER" migrate --from "$framing_authoritative"
)"
framing_legacy="$TMP/digest-framing-legacy"
mkdir -p "$framing_legacy/dist-deck"
printf 'F\000b\000420\000x' >"$framing_legacy/dist-deck/a"
chmod 0755 "$framing_legacy/dist-deck"
chmod 0644 "$framing_legacy/dist-deck/a"
framing_cache_before="$(snapshot "$framing_base")"
framing_source_before="$(snapshot "$framing_legacy")"
if SCV_DECK_CACHE_DIR="$framing_base" \
    bash "$HELPER" migrate --from "$framing_legacy" \
    >/dev/null 2>"$TMP/digest-framing-strict.err"; then
  echo "ambiguous runtime digest records collided" >&2
  exit 1
fi
grep -q 'migration collision' "$TMP/digest-framing-strict.err"
framing_stdout="$(
  SCV_DECK_CACHE_DIR="$framing_base" \
    bash "$HELPER" migrate --from "$framing_legacy" \
    --reuse-existing \
    2>"$TMP/digest-framing-reuse.err"
)"
[[ "$framing_stdout" == "$framing_runtime" ]]
[[ "$(cat "$TMP/digest-framing-reuse.err")" == "$reuse_notice" ]]
[[ "$framing_cache_before" == "$(snapshot "$framing_base")" ]]
[[ "$framing_source_before" == "$(snapshot "$framing_legacy")" ]]

# With no differing destination, opt-in mode retains normal additive behavior.
additive_base="$TMP/reuse-additive-cache"
additive_legacy="$TMP/reuse-additive-legacy"
mkdir -p "$additive_legacy/dist-deck"
printf 'additive\n' >"$additive_legacy/dist-deck/index.html"
additive_source_before="$(snapshot "$additive_legacy")"
additive_runtime="$(
  SCV_DECK_CACHE_DIR="$additive_base" \
    bash "$HELPER" migrate --from "$additive_legacy" --reuse-existing \
    2>"$TMP/reuse-additive.err"
)"
[[ ! -s "$TMP/reuse-additive.err" ]]
cmp \
  "$additive_legacy/dist-deck/index.html" \
  "$additive_runtime/dist-deck/index.html"
[[ "$additive_source_before" == "$(snapshot "$additive_legacy")" ]]

# An equal existing entry plus a missing entry also remains additive.
mkdir -p "$additive_legacy/src/deck/decks/additive-host"
printf '{"additive":true}\n' \
  >"$additive_legacy/src/deck/decks/additive-host/deck.json"
equal_missing_before="$(snapshot "$additive_legacy")"
equal_missing_stdout="$(
  SCV_DECK_CACHE_DIR="$additive_base" \
    bash "$HELPER" migrate --from "$additive_legacy" --reuse-existing \
    2>"$TMP/reuse-equal-missing.err"
)"
[[ "$equal_missing_stdout" == "$additive_runtime" ]]
[[ ! -s "$TMP/reuse-equal-missing.err" ]]
cmp \
  "$additive_legacy/src/deck/decks/additive-host/deck.json" \
  "$additive_runtime/src/deck/decks/additive-host/deck.json"
[[ "$equal_missing_before" == "$(snapshot "$additive_legacy")" ]]

# A collision never short-circuits validation of a later unsafe source entry.
reuse_unsafe_legacy="$TMP/reuse-unsafe-legacy"
mkdir -p \
  "$reuse_unsafe_legacy/node_modules/pkg" \
  "$reuse_unsafe_legacy/src/deck/decks"
printf 'different\n' \
  >"$reuse_unsafe_legacy/node_modules/pkg/index.js"
ln -s "$TMP" "$reuse_unsafe_legacy/src/deck/decks/escaped"
reuse_unsafe_before="$(snapshot "$reuse_unsafe_legacy")"
if SCV_DECK_CACHE_DIR="$reuse_base" \
    bash "$HELPER" migrate --from "$reuse_unsafe_legacy" \
    --reuse-existing \
    >"$TMP/reuse-unsafe.out" 2>"$TMP/reuse-unsafe.err"; then
  echo "reuse mode accepted an unsafe later legacy entry" >&2
  exit 1
fi
[[ ! -s "$TMP/reuse-unsafe.out" ]]
! grep -q '^NOTICE:' "$TMP/reuse-unsafe.err"
[[ "$reuse_cache_before" == "$(snapshot "$reuse_base")" ]]
[[ "$reuse_unsafe_before" == "$(snapshot "$reuse_unsafe_legacy")" ]]

# A source content change after conflict preflight fails before NOTICE or cache
# mutation, while preserving the external writer's source change.
reuse_source_drift_base="$TMP/reuse-source-drift-cache"
reuse_source_drift_authoritative="$TMP/reuse-source-drift-authoritative"
reuse_source_drift_legacy="$TMP/reuse-source-drift-legacy"
prepare_reuse_collision \
  "$reuse_source_drift_base" \
  "$reuse_source_drift_authoritative" \
  "$reuse_source_drift_legacy"
reuse_source_drift_cache_before="$(snapshot "$reuse_source_drift_base")"
reuse_source_drift_ready="$TMP/reuse-source-drift.ready"
reuse_source_drift_continue="$TMP/reuse-source-drift.continue"
SCV_DECK_CACHE_DIR="$reuse_source_drift_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=migrate-reuse-before-revalidate \
SCV_DECK_RUNTIME_TEST_READY_FILE="$reuse_source_drift_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$reuse_source_drift_continue" \
  bash "$HELPER" migrate --from "$reuse_source_drift_legacy" \
  --reuse-existing \
  >"$TMP/reuse-source-drift.out" \
  2>"$TMP/reuse-source-drift.err" &
reuse_source_drift_pid=$!
wait_for_pause \
  "$reuse_source_drift_ready" \
  "$reuse_source_drift_pid" \
  "$TMP/reuse-source-drift.err" \
  "reuse source-content drift"
printf 'externally-changed\n' \
  >"$reuse_source_drift_legacy/node_modules/pkg/index.js"
reuse_source_changed="$(snapshot "$reuse_source_drift_legacy")"
expect_paused_failure \
  "$reuse_source_drift_pid" \
  "$reuse_source_drift_continue" \
  "reuse source-content drift"
[[ ! -s "$TMP/reuse-source-drift.out" ]]
! grep -q '^NOTICE:' "$TMP/reuse-source-drift.err"
grep -q 'legacy Deck runtime changed during reuse preflight' \
  "$TMP/reuse-source-drift.err"
[[ \
  "$reuse_source_drift_cache_before" \
  == "$(snapshot "$reuse_source_drift_base")" \
]]
[[ \
  "$reuse_source_changed" \
  == "$(snapshot "$reuse_source_drift_legacy")" \
]]
assert_no_runtime_debris "$reuse_source_drift_base"

# Adding a newly eligible entry after preflight is also detected by exact
# source entry-set re-enumeration.
reuse_entry_drift_base="$TMP/reuse-entry-drift-cache"
reuse_entry_drift_authoritative="$TMP/reuse-entry-drift-authoritative"
reuse_entry_drift_legacy="$TMP/reuse-entry-drift-legacy"
prepare_reuse_collision \
  "$reuse_entry_drift_base" \
  "$reuse_entry_drift_authoritative" \
  "$reuse_entry_drift_legacy"
reuse_entry_drift_cache_before="$(snapshot "$reuse_entry_drift_base")"
reuse_entry_drift_ready="$TMP/reuse-entry-drift.ready"
reuse_entry_drift_continue="$TMP/reuse-entry-drift.continue"
SCV_DECK_CACHE_DIR="$reuse_entry_drift_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=migrate-reuse-before-revalidate \
SCV_DECK_RUNTIME_TEST_READY_FILE="$reuse_entry_drift_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$reuse_entry_drift_continue" \
  bash "$HELPER" migrate --from "$reuse_entry_drift_legacy" \
  --reuse-existing \
  >"$TMP/reuse-entry-drift.out" \
  2>"$TMP/reuse-entry-drift.err" &
reuse_entry_drift_pid=$!
wait_for_pause \
  "$reuse_entry_drift_ready" \
  "$reuse_entry_drift_pid" \
  "$TMP/reuse-entry-drift.err" \
  "reuse source-entry drift"
mkdir -p "$reuse_entry_drift_legacy/dist-deck"
printf 'late-entry\n' \
  >"$reuse_entry_drift_legacy/dist-deck/index.html"
reuse_entry_changed="$(snapshot "$reuse_entry_drift_legacy")"
expect_paused_failure \
  "$reuse_entry_drift_pid" \
  "$reuse_entry_drift_continue" \
  "reuse source-entry drift"
[[ ! -s "$TMP/reuse-entry-drift.out" ]]
! grep -q '^NOTICE:' "$TMP/reuse-entry-drift.err"
grep -q 'entry set changed during reuse preflight' \
  "$TMP/reuse-entry-drift.err"
[[ \
  "$reuse_entry_drift_cache_before" \
  == "$(snapshot "$reuse_entry_drift_base")" \
]]
[[ \
  "$reuse_entry_changed" \
  == "$(snapshot "$reuse_entry_drift_legacy")" \
]]
assert_no_runtime_debris "$reuse_entry_drift_base"

# Every preflight destination, not only the differing one, is revalidated.
reuse_destination_drift_base="$TMP/reuse-destination-drift-cache"
reuse_destination_drift_authoritative="$TMP/reuse-destination-drift-authoritative"
reuse_destination_drift_legacy="$TMP/reuse-destination-drift-legacy"
prepare_reuse_collision \
  "$reuse_destination_drift_base" \
  "$reuse_destination_drift_authoritative" \
  "$reuse_destination_drift_legacy"
mkdir -p "$reuse_destination_drift_legacy/dist-deck"
printf 'legacy-missing-entry\n' \
  >"$reuse_destination_drift_legacy/dist-deck/index.html"
reuse_destination_drift_runtime="$(
  SCV_DECK_CACHE_DIR="$reuse_destination_drift_base" bash "$HELPER" path
)"
reuse_destination_drift_source_before="$(
  snapshot "$reuse_destination_drift_legacy"
)"
reuse_destination_drift_ready="$TMP/reuse-destination-drift.ready"
reuse_destination_drift_continue="$TMP/reuse-destination-drift.continue"
SCV_DECK_CACHE_DIR="$reuse_destination_drift_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=migrate-reuse-before-revalidate \
SCV_DECK_RUNTIME_TEST_READY_FILE="$reuse_destination_drift_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$reuse_destination_drift_continue" \
  bash "$HELPER" migrate --from "$reuse_destination_drift_legacy" \
  --reuse-existing \
  >"$TMP/reuse-destination-drift.out" \
  2>"$TMP/reuse-destination-drift.err" &
reuse_destination_drift_pid=$!
wait_for_pause \
  "$reuse_destination_drift_ready" \
  "$reuse_destination_drift_pid" \
  "$TMP/reuse-destination-drift.err" \
  "reuse destination drift"
mkdir "$reuse_destination_drift_runtime/dist-deck"
printf 'externally-created-cache\n' \
  >"$reuse_destination_drift_runtime/dist-deck/index.html"
reuse_destination_changed="$(
  snapshot "$reuse_destination_drift_runtime"
)"
expect_paused_failure \
  "$reuse_destination_drift_pid" \
  "$reuse_destination_drift_continue" \
  "reuse destination drift"
[[ ! -s "$TMP/reuse-destination-drift.out" ]]
! grep -q '^NOTICE:' "$TMP/reuse-destination-drift.err"
grep -q 'cache changed during reuse preflight' \
  "$TMP/reuse-destination-drift.err"
[[ \
  "$reuse_destination_drift_source_before" \
  == "$(snapshot "$reuse_destination_drift_legacy")" \
]]
[[ \
  "$reuse_destination_changed" \
  == "$(snapshot "$reuse_destination_drift_runtime")" \
]]
assert_no_runtime_debris "$reuse_destination_drift_base"

# A signal at the reuse decision boundary exits conventionally and leaves no
# false success output, NOTICE, or transaction debris.
reuse_signal_base="$TMP/reuse-signal-cache"
reuse_signal_authoritative="$TMP/reuse-signal-authoritative"
reuse_signal_legacy="$TMP/reuse-signal-legacy"
prepare_reuse_collision \
  "$reuse_signal_base" \
  "$reuse_signal_authoritative" \
  "$reuse_signal_legacy"
reuse_signal_cache_before="$(snapshot "$reuse_signal_base")"
reuse_signal_source_before="$(snapshot "$reuse_signal_legacy")"
reuse_signal_ready="$TMP/reuse-signal.ready"
reuse_signal_continue="$TMP/reuse-signal.continue"
SCV_DECK_CACHE_DIR="$reuse_signal_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=migrate-reuse-before-revalidate \
SCV_DECK_RUNTIME_TEST_READY_FILE="$reuse_signal_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$reuse_signal_continue" \
  bash "$HELPER" migrate --from "$reuse_signal_legacy" \
  --reuse-existing \
  >"$TMP/reuse-signal.out" 2>"$TMP/reuse-signal.err" &
reuse_signal_pid=$!
wait_for_pause \
  "$reuse_signal_ready" "$reuse_signal_pid" "$TMP/reuse-signal.err" \
  "reuse decision TERM cleanup"
kill -TERM "$reuse_signal_pid"
set +e
wait "$reuse_signal_pid"
reuse_signal_rc=$?
set -e
[[ "$reuse_signal_rc" -eq 143 ]]
[[ ! -s "$TMP/reuse-signal.out" ]]
! grep -q '^NOTICE:' "$TMP/reuse-signal.err"
[[ "$reuse_signal_cache_before" == "$(snapshot "$reuse_signal_base")" ]]
[[ "$reuse_signal_source_before" == "$(snapshot "$reuse_signal_legacy")" ]]
assert_no_runtime_debris "$reuse_signal_base"

# NOTICE is emitted only after lock release and visible cache revalidation.
reuse_release_base="$TMP/reuse-release-cache"
reuse_release_authoritative="$TMP/reuse-release-authoritative"
reuse_release_legacy="$TMP/reuse-release-legacy"
prepare_reuse_collision \
  "$reuse_release_base" \
  "$reuse_release_authoritative" \
  "$reuse_release_legacy"
reuse_release_runtime="$(
  SCV_DECK_CACHE_DIR="$reuse_release_base" bash "$HELPER" path
)"
reuse_release_key="$(basename "$(dirname "$reuse_release_runtime")")"
reuse_release_lock="$reuse_release_base/.$reuse_release_key.lock"
reuse_release_saved="$reuse_release_lock.saved"
reuse_release_owner="$TMP/reuse-release-owner"
reuse_release_ready="$TMP/reuse-release.ready"
reuse_release_continue="$TMP/reuse-release.continue"
reuse_release_cache_before="$(snapshot "$reuse_release_runtime")"
reuse_release_source_before="$(snapshot "$reuse_release_legacy")"
printf 'external-owner\n' >"$reuse_release_owner"
SCV_DECK_CACHE_DIR="$reuse_release_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=release-before-delete \
SCV_DECK_RUNTIME_TEST_READY_FILE="$reuse_release_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$reuse_release_continue" \
  bash "$HELPER" migrate --from "$reuse_release_legacy" \
  --reuse-existing \
  >"$TMP/reuse-release.out" 2>"$TMP/reuse-release.err" &
reuse_release_pid=$!
wait_for_pause \
  "$reuse_release_ready" "$reuse_release_pid" \
  "$TMP/reuse-release.err" \
  "reuse lock-release replacement"
mv "$reuse_release_lock" "$reuse_release_saved"
mkdir "$reuse_release_lock"
ln -s "$reuse_release_owner" "$reuse_release_lock/owner.json"
printf 'preserve\n' >"$reuse_release_lock/unexpected"
expect_paused_failure \
  "$reuse_release_pid" "$reuse_release_continue" \
  "reuse lock-release replacement"
[[ ! -s "$TMP/reuse-release.out" ]]
! grep -q '^NOTICE:' "$TMP/reuse-release.err"
[[ -f "$reuse_release_saved/owner.json" ]]
[[ "$reuse_release_cache_before" == "$(snapshot "$reuse_release_runtime")" ]]
[[ "$reuse_release_source_before" == "$(snapshot "$reuse_release_legacy")" ]]

# A destination that appears after a clean preflight is a late race even when
# its bytes and modes equal the source. Reuse mode must fail, not reinterpret it
# as an authoritative pre-existing cache.
late_equal_base="$TMP/late-equal-cache"
late_equal_runtime="$(
  SCV_DECK_CACHE_DIR="$late_equal_base" bash "$HELPER" ensure
)"
late_equal_legacy="$TMP/late-equal-legacy"
mkdir -p "$late_equal_legacy/dist-deck"
printf 'same-late-entry\n' >"$late_equal_legacy/dist-deck/index.html"
late_equal_source_before="$(snapshot "$late_equal_legacy")"
late_equal_ready="$TMP/late-equal.ready"
late_equal_continue="$TMP/late-equal.continue"
SCV_DECK_CACHE_DIR="$late_equal_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=migrate-before-copy \
SCV_DECK_RUNTIME_TEST_READY_FILE="$late_equal_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$late_equal_continue" \
  bash "$HELPER" migrate --from "$late_equal_legacy" \
  --reuse-existing \
  >"$TMP/late-equal.out" 2>"$TMP/late-equal.err" &
late_equal_pid=$!
wait_for_pause \
  "$late_equal_ready" "$late_equal_pid" "$TMP/late-equal.err" \
  "late equal destination"
cp -R -p \
  "$late_equal_legacy/dist-deck" \
  "$late_equal_runtime/dist-deck"
late_equal_inode="$(
  python3 - "$late_equal_runtime/dist-deck" <<'PY'
import os
import sys
print(os.lstat(sys.argv[1]).st_ino)
PY
)"
expect_paused_failure \
  "$late_equal_pid" "$late_equal_continue" \
  "late equal destination"
late_equal_inode_after="$(
  python3 - "$late_equal_runtime/dist-deck" <<'PY'
import os
import sys
print(os.lstat(sys.argv[1]).st_ino)
PY
)"
[[ "$late_equal_inode" == "$late_equal_inode_after" ]]
[[ ! -s "$TMP/late-equal.out" ]]
! grep -q '^NOTICE:' "$TMP/late-equal.err"
grep -q 'cache changed after migration preflight' \
  "$TMP/late-equal.err"
[[ "$late_equal_source_before" == "$(snapshot "$late_equal_legacy")" ]]
assert_no_runtime_debris "$late_equal_base"

# A destination created after collision preflight is never replaced.
race_base="$TMP/race-cache"
race_runtime="$(
  SCV_DECK_CACHE_DIR="$race_base" bash "$HELPER" ensure
)"
race_legacy="$TMP/race-legacy"
mkdir -p "$race_legacy/dist-deck"
python3 - "$race_legacy/dist-deck" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = b"x" * 1024
for index in range(4000):
    (root / f"{index:04d}.bin").write_bytes(payload)
PY
SCV_DECK_CACHE_DIR="$race_base" \
  bash "$HELPER" migrate --from "$race_legacy" \
  --reuse-existing \
  >"$TMP/race.out" 2>"$TMP/race.err" &
race_pid=$!
race_stage=
for _ in $(seq 1 1000); do
  race_stage="$(
    find "$(dirname "$race_runtime")" -maxdepth 1 \
      -type d -name '.dist-deck.stage-*' -print -quit
  )"
  [[ -n "$race_stage" ]] && break
done
[[ -n "$race_stage" ]]
mkdir "$race_runtime/dist-deck"
race_inode_before="$(
  python3 - "$race_runtime/dist-deck" <<'PY'
import os
import sys
print(os.lstat(sys.argv[1]).st_ino)
PY
)"
if wait "$race_pid"; then
  echo "concurrent cache destination was replaced" >&2
  exit 1
fi
race_inode_after="$(
  python3 - "$race_runtime/dist-deck" <<'PY'
import os
import sys
print(os.lstat(sys.argv[1]).st_ino)
PY
)"
[[ "$race_inode_before" == "$race_inode_after" ]]
[[ -z "$(find "$race_runtime/dist-deck" -mindepth 1 -print -quit)" ]]
grep -q 'cache changed after migration preflight' "$TMP/race.err"
! grep -q '^NOTICE:' "$TMP/race.err"

# A copy failure immediately after top-level stage creation removes only that
# exact stage inode. No partial target, source mutation, or staging debris
# remains (the same cleanup path covers source races and ENOSPC).
stage_fail_base="$TMP/ensure-stage-fail-cache"
stage_fail_target="$(
  SCV_DECK_CACHE_DIR="$stage_fail_base" bash "$HELPER" path
)"
stage_fail_namespace="$(dirname "$stage_fail_target")"
if SCV_DECK_CACHE_DIR="$stage_fail_base" \
    SCV_DECK_RUNTIME_TEST_FAIL=ensure-stage-created \
    bash "$HELPER" ensure >/dev/null 2>"$TMP/ensure-stage-fail.err"; then
  echo "injected ensure staging failure unexpectedly succeeded" >&2
  exit 1
fi
[[ ! -e "$stage_fail_target" ]]
[[ -z "$(
  find "$stage_fail_namespace" -maxdepth 1 \
    -name '.DeckUI.stage-*' -print -quit
)" ]]
[[ "$before" == "$(snapshot "$SOURCE")" ]]

migrate_fail_base="$TMP/migrate-stage-fail-cache"
migrate_fail_runtime="$(
  SCV_DECK_CACHE_DIR="$migrate_fail_base" bash "$HELPER" ensure
)"
migrate_fail_namespace="$(dirname "$migrate_fail_runtime")"
migrate_fail_legacy="$TMP/migrate-stage-fail-legacy"
mkdir -p "$migrate_fail_legacy/dist-deck"
printf 'legacy\n' >"$migrate_fail_legacy/dist-deck/index.html"
migrate_fail_before="$(snapshot "$migrate_fail_legacy")"
if SCV_DECK_CACHE_DIR="$migrate_fail_base" \
    SCV_DECK_RUNTIME_TEST_FAIL=migrate-stage-created \
    bash "$HELPER" migrate --from "$migrate_fail_legacy" \
    >/dev/null 2>"$TMP/migrate-stage-fail.err"; then
  echo "injected migration staging failure unexpectedly succeeded" >&2
  exit 1
fi
[[ ! -e "$migrate_fail_runtime/dist-deck" ]]
[[ -z "$(
  find "$migrate_fail_namespace" -maxdepth 1 \
    -name '.dist-deck.stage-*' -print -quit
)" ]]
[[ "$migrate_fail_before" == "$(snapshot "$migrate_fail_legacy")" ]]

install_fail_base="$TMP/install-stage-fail-cache"
install_fail_runtime="$(
  SCV_DECK_CACHE_DIR="$install_fail_base" bash "$HELPER" ensure
)"
install_fail_namespace="$(dirname "$install_fail_runtime")"
install_fail_legacy="$TMP/install-stage-fail-legacy"
mkdir -p "$install_fail_legacy/dist-deck"
printf 'readonly\n' >"$install_fail_legacy/dist-deck/index.html"
chmod 0555 "$install_fail_legacy/dist-deck"
install_fail_before="$(snapshot "$install_fail_legacy")"
if SCV_DECK_CACHE_DIR="$install_fail_base" \
    SCV_DECK_RUNTIME_TEST_FAIL=migrate-install-stage-created \
    bash "$HELPER" migrate --from "$install_fail_legacy" \
    >/dev/null 2>"$TMP/install-stage-fail.err"; then
  echo "injected install staging failure unexpectedly succeeded" >&2
  exit 1
fi
[[ ! -e "$install_fail_runtime/dist-deck" ]]
[[ -z "$(
  find "$install_fail_namespace" -maxdepth 1 \
    -name '.dist-deck.stage-*' -print -quit
)" ]]
[[ -z "$(
  find "$install_fail_runtime" -maxdepth 1 \
    -name '.dist-deck.install-*' -print -quit
)" ]]
[[ "$install_fail_before" == "$(snapshot "$install_fail_legacy")" ]]

nested_fail_base="$TMP/nested-parent-fail-cache"
nested_fail_runtime="$(
  SCV_DECK_CACHE_DIR="$nested_fail_base" bash "$HELPER" ensure
)"
nested_fail_namespace="$(dirname "$nested_fail_runtime")"
nested_fail_legacy="$TMP/nested-parent-fail-legacy"
nested_fail_deck="$nested_fail_legacy/src/deck/decks/audit-generated"
mkdir -p "$nested_fail_deck"
printf '{"audit":true}\n' >"$nested_fail_deck/deck.json"
nested_fail_before="$(snapshot "$nested_fail_legacy")"
if SCV_DECK_CACHE_DIR="$nested_fail_base" \
    SCV_DECK_RUNTIME_TEST_FAIL=migrate-parent-created \
    bash "$HELPER" migrate --from "$nested_fail_legacy" \
    >/dev/null 2>"$TMP/nested-parent-fail.err"; then
  echo "injected nested migration failure unexpectedly succeeded" >&2
  exit 1
fi
[[ \
  ! -e \
  "$nested_fail_runtime/src/deck/decks/audit-generated" \
]]
[[ -z "$(
  find "$nested_fail_namespace" -maxdepth 1 \
    -name '.deck.json.stage-*' -print -quit
)" ]]
[[ "$nested_fail_before" == "$(snapshot "$nested_fail_legacy")" ]]

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

# Cache destination ancestors are opened without following links.
ancestor_legacy="$TMP/ancestor-legacy"
ancestor_outside="$TMP/ancestor-outside"
mkdir -p \
  "$ancestor_legacy/src/deck/decks/escaped" \
  "$ancestor_outside"
printf '{"escaped":true}\n' \
  >"$ancestor_legacy/src/deck/decks/escaped/deck.json"
ln -s "$ancestor_outside" "$runtime/src/deck/decks/escaped"
if SCV_DECK_CACHE_DIR="$cache_base" \
    bash "$HELPER" migrate --from "$ancestor_legacy" >/dev/null 2>&1; then
  echo "cache destination ancestor symlink was followed" >&2
  exit 1
fi
[[ -z "$(find "$ancestor_outside" -mindepth 1 -print -quit)" ]]

# Cache and legacy roots may not overlap, and rejection happens before cache
# initialization mutates the legacy tree.
overlap_legacy="$TMP/overlap-legacy"
mkdir -p "$overlap_legacy/node_modules"
printf 'legacy\n' >"$overlap_legacy/node_modules/sentinel"
if SCV_DECK_CACHE_DIR="$overlap_legacy/cache" \
    bash "$HELPER" migrate --from "$overlap_legacy" >/dev/null 2>&1; then
  echo "cache nested under the legacy DeckUI was accepted" >&2
  exit 1
fi
[[ ! -e "$overlap_legacy/cache" ]]
mkdir -p "$runtime/legacy-inside-cache"
if SCV_DECK_CACHE_DIR="$cache_base" \
    bash "$HELPER" migrate \
      --from "$runtime/legacy-inside-cache" >/dev/null 2>&1; then
  echo "legacy DeckUI nested under the cache was accepted" >&2
  exit 1
fi

# Malformed or surprising lock state is preserved and fails closed. A valid
# lock whose owner has exited is the only state eligible for stale reclaim.
make_dead_pid() {
  sleep 30 &
  local child=$!
  kill "$child"
  wait "$child" 2>/dev/null || true
  printf '%s\n' "$child"
}

malformed_base="$TMP/malformed-lock-cache"
malformed_runtime="$(
  SCV_DECK_CACHE_DIR="$malformed_base" bash "$HELPER" path
)"
malformed_key="$(basename "$(dirname "$malformed_runtime")")"
malformed_lock="$malformed_base/.$malformed_key.lock"
mkdir -p "$malformed_lock"
printf '{broken\n' >"$malformed_lock/owner.json"
python3 - "$malformed_lock" <<'PY'
import os
import sys
import time

old = time.time() - 10
os.utime(sys.argv[1], (old, old))
PY
if SCV_DECK_CACHE_DIR="$malformed_base" \
    bash "$HELPER" ensure >/dev/null 2>&1; then
  echo "malformed runtime lock was reclaimed" >&2
  exit 1
fi
grep -qF '{broken' "$malformed_lock/owner.json"

# JSON values that merely coerce to an integer are malformed lock owners.
for invalid_pid_case in string float bool; do
  invalid_pid_base="$TMP/invalid-pid-$invalid_pid_case-cache"
  invalid_pid_runtime="$(
    SCV_DECK_CACHE_DIR="$invalid_pid_base" bash "$HELPER" path
  )"
  invalid_pid_key="$(basename "$(dirname "$invalid_pid_runtime")")"
  invalid_pid_lock="$invalid_pid_base/.$invalid_pid_key.lock"
  mkdir -p "$invalid_pid_lock"
  case "$invalid_pid_case" in
    string) invalid_pid_value='"999999"' ;;
    float) invalid_pid_value='999999.0' ;;
    bool) invalid_pid_value='true' ;;
  esac
  printf '{"pid":%s,"token":"abababababababababababababababab"}\n' \
    "$invalid_pid_value" >"$invalid_pid_lock/owner.json"
  python3 - "$invalid_pid_lock" <<'PY'
import os
import sys
import time

old = time.time() - 10
os.utime(sys.argv[1], (old, old))
PY
  invalid_pid_before="$(snapshot "$invalid_pid_lock")"
  if SCV_DECK_CACHE_DIR="$invalid_pid_base" \
      bash "$HELPER" ensure >/dev/null \
      2>"$TMP/invalid-pid-$invalid_pid_case.err"; then
    echo "non-integer lock pid was accepted: $invalid_pid_case" >&2
    exit 1
  fi
  [[ "$invalid_pid_before" == "$(snapshot "$invalid_pid_lock")" ]]
  grep -qF 'lock metadata is malformed' \
    "$TMP/invalid-pid-$invalid_pid_case.err"
done

extra_base="$TMP/extra-lock-cache"
extra_runtime="$(
  SCV_DECK_CACHE_DIR="$extra_base" bash "$HELPER" path
)"
extra_key="$(basename "$(dirname "$extra_runtime")")"
extra_lock="$extra_base/.$extra_key.lock"
mkdir -p "$extra_lock"
dead_pid="$(make_dead_pid)"
printf '{"pid":%s,"token":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}\n' \
  "$dead_pid" >"$extra_lock/owner.json"
printf 'preserve\n' >"$extra_lock/unexpected"
if SCV_DECK_CACHE_DIR="$extra_base" \
    bash "$HELPER" ensure >/dev/null 2>&1; then
  echo "stale runtime lock with unexpected data was reclaimed" >&2
  exit 1
fi
grep -qF preserve "$extra_lock/unexpected"

stale_base="$TMP/stale-lock-cache"
stale_runtime="$(
  SCV_DECK_CACHE_DIR="$stale_base" bash "$HELPER" path
)"
stale_key="$(basename "$(dirname "$stale_runtime")")"
stale_lock="$stale_base/.$stale_key.lock"
mkdir -p "$stale_lock"
dead_pid="$(make_dead_pid)"
printf '{"pid":%s,"token":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}\n' \
  "$dead_pid" >"$stale_lock/owner.json"
reclaimed="$(
  SCV_DECK_CACHE_DIR="$stale_base" bash "$HELPER" ensure
)"
[[ "$reclaimed" == "$stale_runtime" ]]
[[ ! -e "$stale_lock" ]]

# An atomically-installed lock is reopened without following a late symlink.
acquire_base="$TMP/acquire-race-cache"
acquire_outside="$TMP/acquire-race-outside"
acquire_ready="$TMP/acquire-race.ready"
acquire_continue="$TMP/acquire-race.continue"
mkdir -p "$acquire_outside"
printf 'outside\n' >"$acquire_outside/sentinel"
acquire_outside_before="$(snapshot "$acquire_outside")"
SCV_DECK_CACHE_DIR="$acquire_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=acquire-before-open \
SCV_DECK_RUNTIME_TEST_READY_FILE="$acquire_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$acquire_continue" \
  bash "$HELPER" ensure >"$TMP/acquire-race.out" \
  2>"$TMP/acquire-race.err" &
acquire_pid=$!
wait_for_pause \
  "$acquire_ready" "$acquire_pid" "$TMP/acquire-race.err" \
  "late installed-lock symlink race"
acquire_candidate="$(sed -n '1p' "$acquire_ready")"
mv \
  "$acquire_base/$acquire_candidate" \
  "$acquire_base/$acquire_candidate.saved"
ln -s "$acquire_outside" "$acquire_base/$acquire_candidate"
expect_paused_failure \
  "$acquire_pid" "$acquire_continue" \
  "late installed-lock symlink race"
[[ -L "$acquire_base/$acquire_candidate" ]]
[[ -f "$acquire_base/$acquire_candidate.saved/owner.json" ]]
[[ "$acquire_outside_before" == "$(snapshot "$acquire_outside")" ]]

# Catchable termination while an empty lock candidate is paused removes only
# that exact candidate and exits with the conventional 128+signal status.
signal_base="$TMP/candidate-signal-cache"
signal_ready="$TMP/candidate-signal.ready"
signal_continue="$TMP/candidate-signal.continue"
SCV_DECK_CACHE_DIR="$signal_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=candidate-before-open \
SCV_DECK_RUNTIME_TEST_READY_FILE="$signal_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$signal_continue" \
  bash "$HELPER" ensure >"$TMP/candidate-signal.out" \
  2>"$TMP/candidate-signal.err" &
signal_pid=$!
wait_for_pause \
  "$signal_ready" "$signal_pid" "$TMP/candidate-signal.err" \
  "lock-candidate TERM cleanup"
signal_candidate="$(sed -n '1p' "$signal_ready")"
kill -TERM "$signal_pid"
set +e
wait "$signal_pid"
signal_rc=$?
set -e
[[ "$signal_rc" -eq 143 ]]
[[ ! -e "$signal_base/$signal_candidate" ]]
[[ -z "$(
  find "$signal_base" -maxdepth 1 \
    -name '.*.lock.new-*' -print -quit
)" ]]
[[ ! -s "$TMP/candidate-signal.out" ]]

# An existing stale lock replaced by a symlink between lstat and open is
# preserved and never followed.
lock_open_base="$TMP/lock-open-race-cache"
lock_open_runtime="$(
  SCV_DECK_CACHE_DIR="$lock_open_base" bash "$HELPER" path
)"
lock_open_key="$(basename "$(dirname "$lock_open_runtime")")"
lock_open_lock="$lock_open_base/.$lock_open_key.lock"
lock_open_outside="$TMP/lock-open-race-outside"
lock_open_ready="$TMP/lock-open-race.ready"
lock_open_continue="$TMP/lock-open-race.continue"
mkdir -p "$lock_open_lock" "$lock_open_outside"
dead_pid="$(make_dead_pid)"
printf '{"pid":%s,"token":"cccccccccccccccccccccccccccccccc"}\n' \
  "$dead_pid" >"$lock_open_lock/owner.json"
printf 'outside\n' >"$lock_open_outside/sentinel"
lock_open_outside_before="$(snapshot "$lock_open_outside")"
SCV_DECK_CACHE_DIR="$lock_open_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=lock-before-open \
SCV_DECK_RUNTIME_TEST_READY_FILE="$lock_open_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$lock_open_continue" \
  bash "$HELPER" ensure >"$TMP/lock-open-race.out" \
  2>"$TMP/lock-open-race.err" &
lock_open_pid=$!
wait_for_pause \
  "$lock_open_ready" "$lock_open_pid" "$TMP/lock-open-race.err" \
  "late existing-lock symlink race"
mv "$lock_open_lock" "$lock_open_lock.saved"
ln -s "$lock_open_outside" "$lock_open_lock"
expect_paused_failure \
  "$lock_open_pid" "$lock_open_continue" \
  "late existing-lock symlink race"
[[ -L "$lock_open_lock" ]]
[[ -f "$lock_open_lock.saved/owner.json" ]]
[[ "$lock_open_outside_before" == "$(snapshot "$lock_open_outside")" ]]

# A stale-quarantine destination collision is never replaced. Reclamation
# retries with a new name and leaves the colliding entry byte-for-byte intact.
quarantine_base="$TMP/quarantine-collision-cache"
quarantine_runtime="$(
  SCV_DECK_CACHE_DIR="$quarantine_base" bash "$HELPER" path
)"
quarantine_key="$(basename "$(dirname "$quarantine_runtime")")"
quarantine_lock="$quarantine_base/.$quarantine_key.lock"
quarantine_ready="$TMP/quarantine-collision.ready"
quarantine_continue="$TMP/quarantine-collision.continue"
mkdir -p "$quarantine_lock"
dead_pid="$(make_dead_pid)"
printf '{"pid":%s,"token":"dddddddddddddddddddddddddddddddd"}\n' \
  "$dead_pid" >"$quarantine_lock/owner.json"
SCV_DECK_CACHE_DIR="$quarantine_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=stale-before-rename \
SCV_DECK_RUNTIME_TEST_READY_FILE="$quarantine_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$quarantine_continue" \
  bash "$HELPER" ensure >"$TMP/quarantine-collision.out" \
  2>"$TMP/quarantine-collision.err" &
quarantine_pid=$!
wait_for_pause \
  "$quarantine_ready" "$quarantine_pid" \
  "$TMP/quarantine-collision.err" \
  "stale quarantine collision"
quarantine_name="$(sed -n '1p' "$quarantine_ready")"
mkdir "$quarantine_base/$quarantine_name"
printf 'preserve\n' >"$quarantine_base/$quarantine_name/sentinel"
: >"$quarantine_continue"
wait "$quarantine_pid"
grep -qF preserve "$quarantine_base/$quarantine_name/sentinel"
[[ ! -e "$quarantine_lock" ]]

# Rewriting a stale owner's token in place during quarantine never authorizes
# deletion, even though the owner inode and dead PID remain unchanged.
token_race_base="$TMP/token-race-cache"
token_race_runtime="$(
  SCV_DECK_CACHE_DIR="$token_race_base" bash "$HELPER" path
)"
token_race_key="$(basename "$(dirname "$token_race_runtime")")"
token_race_lock="$token_race_base/.$token_race_key.lock"
token_race_ready="$TMP/token-race.ready"
token_race_continue="$TMP/token-race.continue"
mkdir -p "$token_race_lock"
dead_pid="$(make_dead_pid)"
printf '{"pid":%s,"token":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"}\n' \
  "$dead_pid" >"$token_race_lock/owner.json"
token_race_inode="$(
  python3 - "$token_race_lock/owner.json" <<'PY'
import os
import sys
print(os.lstat(sys.argv[1]).st_ino)
PY
)"
SCV_DECK_CACHE_DIR="$token_race_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=stale-before-rename \
SCV_DECK_RUNTIME_TEST_READY_FILE="$token_race_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$token_race_continue" \
  bash "$HELPER" ensure >"$TMP/token-race.out" \
  2>"$TMP/token-race.err" &
token_race_pid=$!
wait_for_pause \
  "$token_race_ready" "$token_race_pid" "$TMP/token-race.err" \
  "stale owner token mutation"
token_race_quarantine="$(sed -n '1p' "$token_race_ready")"
printf '{"pid":%s,"token":"ffffffffffffffffffffffffffffffff"}\n' \
  "$dead_pid" >"$token_race_lock/owner.json"
token_race_inode_after="$(
  python3 - "$token_race_lock/owner.json" <<'PY'
import os
import sys
print(os.lstat(sys.argv[1]).st_ino)
PY
)"
[[ "$token_race_inode" == "$token_race_inode_after" ]]
expect_paused_failure \
  "$token_race_pid" "$token_race_continue" \
  "stale owner token mutation"
token_race_quarantined="$token_race_base/$token_race_quarantine"
[[ -f "$token_race_quarantined/owner.json" ]]
grep -qF ffffffffffffffffffffffffffffffff \
  "$token_race_quarantined/owner.json"
grep -qF 'ownership changed' "$TMP/token-race.err"

# Once the lock and cache descriptors are open, replacing the visible cache
# base cannot redirect initialization into an external directory.
base_swap_parent="$TMP/base-swap-parent"
base_swap="$base_swap_parent/cache"
base_swap_saved="$TMP/base-swap-parent.saved"
base_swap_outside="$TMP/base-swap-outside"
base_swap_ready="$TMP/base-swap.ready"
base_swap_continue="$TMP/base-swap.continue"
mkdir -p "$base_swap_outside"
printf 'outside\n' >"$base_swap_outside/sentinel"
base_swap_outside_before="$(snapshot "$base_swap_outside")"
SCV_DECK_CACHE_DIR="$base_swap" \
SCV_DECK_RUNTIME_TEST_PAUSE=release-before-delete \
SCV_DECK_RUNTIME_TEST_READY_FILE="$base_swap_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$base_swap_continue" \
  bash "$HELPER" ensure >"$TMP/base-swap.out" \
  2>"$TMP/base-swap.err" &
base_swap_pid=$!
wait_for_pause \
  "$base_swap_ready" "$base_swap_pid" "$TMP/base-swap.err" \
  "late cache-base replacement"
mv "$base_swap_parent" "$base_swap_saved"
ln -s "$base_swap_outside" "$base_swap_parent"
expect_paused_failure \
  "$base_swap_pid" "$base_swap_continue" \
  "late cache-base replacement"
[[ ! -s "$TMP/base-swap.out" ]]
[[ "$base_swap_outside_before" == "$(snapshot "$base_swap_outside")" ]]

# Replacing the payload namespace after lock acquisition likewise cannot
# redirect staging, installation, or cleanup.
namespace_swap_base="$TMP/namespace-swap-cache"
namespace_swap_target="$(
  SCV_DECK_CACHE_DIR="$namespace_swap_base" bash "$HELPER" path
)"
namespace_swap_dir="$(dirname "$namespace_swap_target")"
namespace_swap_saved="$namespace_swap_dir.saved"
namespace_swap_outside="$TMP/namespace-swap-outside"
namespace_swap_ready="$TMP/namespace-swap.ready"
namespace_swap_continue="$TMP/namespace-swap.continue"
mkdir -p "$namespace_swap_outside"
printf 'outside\n' >"$namespace_swap_outside/sentinel"
namespace_swap_outside_before="$(snapshot "$namespace_swap_outside")"
SCV_DECK_CACHE_DIR="$namespace_swap_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=locked-before-operation \
SCV_DECK_RUNTIME_TEST_READY_FILE="$namespace_swap_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$namespace_swap_continue" \
  bash "$HELPER" ensure >"$TMP/namespace-swap.out" \
  2>"$TMP/namespace-swap.err" &
namespace_swap_pid=$!
wait_for_pause \
  "$namespace_swap_ready" "$namespace_swap_pid" \
  "$TMP/namespace-swap.err" \
  "late cache-namespace replacement"
mv "$namespace_swap_dir" "$namespace_swap_saved"
ln -s "$namespace_swap_outside" "$namespace_swap_dir"
expect_paused_failure \
  "$namespace_swap_pid" "$namespace_swap_continue" \
  "late cache-namespace replacement"
[[ \
  "$namespace_swap_outside_before" \
  == "$(snapshot "$namespace_swap_outside")" \
]]

# Migration stays on the already-open target when its visible name is
# replaced, then fails closed without touching the replacement.
target_swap_base="$TMP/target-swap-cache"
target_swap_runtime="$(
  SCV_DECK_CACHE_DIR="$target_swap_base" bash "$HELPER" ensure
)"
target_swap_saved="$target_swap_runtime.saved"
target_swap_outside="$TMP/target-swap-outside"
target_swap_legacy="$TMP/target-swap-legacy"
target_swap_ready="$TMP/target-swap.ready"
target_swap_continue="$TMP/target-swap.continue"
mkdir -p \
  "$target_swap_outside" \
  "$target_swap_legacy/dist-deck"
printf 'outside\n' >"$target_swap_outside/sentinel"
printf 'legacy\n' >"$target_swap_legacy/dist-deck/index.html"
target_swap_outside_before="$(snapshot "$target_swap_outside")"
SCV_DECK_CACHE_DIR="$target_swap_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=target-opened \
SCV_DECK_RUNTIME_TEST_READY_FILE="$target_swap_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$target_swap_continue" \
  bash "$HELPER" migrate --from "$target_swap_legacy" \
  >"$TMP/target-swap.out" 2>"$TMP/target-swap.err" &
target_swap_pid=$!
wait_for_pause \
  "$target_swap_ready" "$target_swap_pid" "$TMP/target-swap.err" \
  "late runtime-target replacement"
mv "$target_swap_runtime" "$target_swap_saved"
ln -s "$target_swap_outside" "$target_swap_runtime"
expect_paused_failure \
  "$target_swap_pid" "$target_swap_continue" \
  "late runtime-target replacement"
[[ -f "$target_swap_saved/dist-deck/index.html" ]]
[[ "$target_swap_outside_before" == "$(snapshot "$target_swap_outside")" ]]

# A lock-path replacement immediately before release is not read, overwritten,
# or deleted. The original lock remains under the attacker's renamed path.
release_base="$TMP/release-race-cache"
release_runtime="$(
  SCV_DECK_CACHE_DIR="$release_base" bash "$HELPER" path
)"
release_key="$(basename "$(dirname "$release_runtime")")"
release_lock="$release_base/.$release_key.lock"
release_saved="$release_lock.saved"
release_outside_owner="$TMP/release-outside-owner"
release_ready="$TMP/release-race.ready"
release_continue="$TMP/release-race.continue"
printf 'outside-owner\n' >"$release_outside_owner"
SCV_DECK_CACHE_DIR="$release_base" \
SCV_DECK_RUNTIME_TEST_PAUSE=release-before-delete \
SCV_DECK_RUNTIME_TEST_READY_FILE="$release_ready" \
SCV_DECK_RUNTIME_TEST_CONTINUE_FILE="$release_continue" \
  bash "$HELPER" ensure >"$TMP/release-race.out" \
  2>"$TMP/release-race.err" &
release_pid=$!
wait_for_pause \
  "$release_ready" "$release_pid" "$TMP/release-race.err" \
  "runtime-lock release replacement"
mv "$release_lock" "$release_saved"
mkdir "$release_lock"
ln -s "$release_outside_owner" "$release_lock/owner.json"
printf 'preserve\n' >"$release_lock/unexpected"
expect_paused_failure \
  "$release_pid" "$release_continue" \
  "runtime-lock release replacement"
[[ -f "$release_saved/owner.json" ]]
[[ -L "$release_lock/owner.json" ]]
grep -qF preserve "$release_lock/unexpected"
grep -qF outside-owner "$release_outside_owner"

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
