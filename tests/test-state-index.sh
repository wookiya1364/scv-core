#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_INDEX="$ROOT/core/scripts/state-index.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "state-index test failed: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$actual" != "$expected" ]]; then
    {
      echo "state-index test failed: $label"
      echo "--- expected ---"
      printf '%s\n' "$expected"
      echo "--- actual ---"
      printf '%s\n' "$actual"
    } >&2
    exit 1
  fi
}

stat_mode() {
  if stat -c '%a' "$1" >/dev/null 2>&1; then
    stat -c '%a' "$1"
  else
    stat -f '%Lp' "$1"
  fi
}

snapshot() {
  local root="$1" path mode
  (
    cd "$root"
    while IFS= read -r path; do
      if [[ -L "$path" ]]; then
        printf 'L %s %s\n' "$path" "$(readlink "$path")"
      elif [[ -d "$path" ]]; then
        mode="$(stat_mode "$path")"
        printf 'D %s %s\n' "$mode" "$path"
      elif [[ -f "$path" ]]; then
        mode="$(stat_mode "$path")"
        printf 'F %s ' "$mode"
        cksum "$path"
      else
        printf 'S %s\n' "$path"
      fi
    done < <(find . -mindepth 1 -print | LC_ALL=C sort)
  )
}

write_profile() {
  local file="$1" host_id="$2" host_label="$3"
  cat > "$file" <<EOF
SCV_HOST_PROFILE_API=1
SCV_HOST_ID=$host_id
SCV_HOST_LABEL=$host_label
SCV_ACTION_TEMPLATE=action:{action}
SCV_ARGUMENT_STYLE=argv-array
SCV_STATE_INDEX=SCV.md
SCV_LEGACY_STATE_INDEXES=CLAUDE.md|CODEX.md
SCV_ROOT_ENV=SCV_CORE_ROOT
SCV_GRAPH_SKILL_PATHS=
SCV_UPDATE_OWNER=adapter
SCV_MODEL_POLICY_OWNER=adapter
EOF
}

CLAUDE_PROFILE="$TMP/claude.env"
CODEX_PROFILE="$TMP/codex.env"
write_profile "$CLAUDE_PROFILE" claude-code "Claude Code"
write_profile "$CODEX_PROFILE" codex "OpenAI Codex"

RUN_OUTPUT=
RUN_RC=0
run_state_index() {
  local profile="$1" project="$2"
  shift 2
  set +e
  RUN_OUTPUT="$(
    SCV_HOST_PROFILE="$profile" \
      bash "$STATE_INDEX" --project-dir "$project" "$@" 2>&1
  )"
  RUN_RC=$?
  set -e
}

assert_read_case() {
  local label="$1" project="$2" expected_rc="$3" expected_output="$4"
  shift 4
  local before after claude_out claude_rc

  before="$(snapshot "$project")"
  run_state_index "$CLAUDE_PROFILE" "$project" "$@"
  claude_out="$RUN_OUTPUT"
  claude_rc="$RUN_RC"
  after="$(snapshot "$project")"
  assert_eq "$before" "$after" "$label: Claude profile mutated the project"

  before="$after"
  run_state_index "$CODEX_PROFILE" "$project" "$@"
  after="$(snapshot "$project")"
  assert_eq "$before" "$after" "$label: Codex profile mutated the project"

  assert_eq "$expected_rc" "$claude_rc" "$label: Claude return code"
  assert_eq "$expected_rc" "$RUN_RC" "$label: Codex return code"
  assert_eq "$claude_out" "$RUN_OUTPUT" "$label: profile stdout/rc semantics drifted"
  assert_eq "$expected_output" "$RUN_OUTPUT" "$label: exact output"
  [[ "$RUN_OUTPUT" != *"$TMP"* ]] \
    || fail "$label: output leaked an absolute fixture path"
}

# Hydration proxy since TEMPLATE_VERSION 2.0.0: scv/PROMOTE.md (INTAKE.md was retired).
new_project() {
  local name="$1" hydrated="${2:-yes}"
  local project="$TMP/fixtures/$name"
  mkdir -p "$project/scv"
  if [[ "$hydrated" == yes ]]; then
    printf '%s\n' '# promote convention' > "$project/scv/PROMOTE.md"
  fi
  printf '%s\n' "$project"
}

write_state() {
  local project="$1" name="$2" content="$3" mode="${4:-644}"
  printf '%s' "$content" > "$project/scv/$name"
  chmod "$mode" "$project/scv/$name"
}

write_pointer() {
  local project="$1" name="$2"
  cat > "$project/scv/$name" <<'EOF'
# SCV host compatibility pointer

<!-- SCV:HOST-POINTER target=SCV.md -->

Read SCV.md.
EOF
}

expected_missing() {
  cat <<'EOF'
STATE_INDEX: missing
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: no
EOF
}

expected_canonical() {
  local hydrated="${1:-yes}"
  cat <<EOF
STATE_INDEX: canonical
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: $hydrated
EOF
}

expected_legacy() {
  local name="$1" hydrated="${2:-yes}"
  cat <<EOF
STATE_INDEX: legacy
STATE_INDEX_FILE: scv/$name
HYDRATED: $hydrated
MIGRATION_AVAILABLE: an approved sync can create scv/SCV.md
EOF
}

expected_canonical_with_migration() {
  local hydrated="${1:-yes}"
  cat <<EOF
STATE_INDEX: canonical
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: $hydrated
MIGRATION_AVAILABLE: an approved sync can replace identical legacy state with pointers
EOF
}

EMPTY_ROOT="$TMP/fixtures/missing-root"
mkdir -p "$EMPTY_ROOT"
assert_read_case missing-root "$EMPTY_ROOT" 0 "$(expected_missing)"

EMPTY="$(new_project empty)"
assert_read_case empty-scv "$EMPTY" 0 "$(expected_missing)"

CANONICAL="$(new_project canonical)"
write_state "$CANONICAL" SCV.md "shared-state"
assert_read_case canonical "$CANONICAL" 0 "$(expected_canonical)"

CLAUDE_ONLY="$(new_project claude-only)"
write_state "$CLAUDE_ONLY" CLAUDE.md "shared-state"
assert_read_case claude-only "$CLAUDE_ONLY" 0 "$(expected_legacy CLAUDE.md)"

CODEX_ONLY="$(new_project codex-only)"
write_state "$CODEX_ONLY" CODEX.md "shared-state"
assert_read_case codex-only "$CODEX_ONLY" 0 "$(expected_legacy CODEX.md)"

EQUAL_DUAL="$(new_project equal-dual)"
write_state "$EQUAL_DUAL" CLAUDE.md "shared-state"
write_state "$EQUAL_DUAL" CODEX.md "shared-state"
assert_read_case equal-dual "$EQUAL_DUAL" 0 "$(expected_legacy CLAUDE.md)"

DIVERGENT_DUAL="$(new_project divergent-dual)"
write_state "$DIVERGENT_DUAL" CLAUDE.md "claude-state"
write_state "$DIVERGENT_DUAL" CODEX.md "codex-state"
assert_read_case divergent-dual "$DIVERGENT_DUAL" 4 "$(cat <<'EOF'
STATE_INDEX_CONFLICT:
  scv/CLAUDE.md <> scv/CODEX.md
STATE_INDEX: legacy
STATE_INDEX_FILE: scv/CLAUDE.md
HYDRATED: yes
MIGRATION_REQUIRED: reconcile the listed state indexes explicitly; no file was overwritten
EOF
)"

CANONICAL_EQUAL_CLAUDE="$(new_project canonical-equal-claude)"
write_state "$CANONICAL_EQUAL_CLAUDE" SCV.md "shared-state"
write_state "$CANONICAL_EQUAL_CLAUDE" CLAUDE.md "shared-state"
assert_read_case canonical-equal-claude "$CANONICAL_EQUAL_CLAUDE" 0 \
  "$(expected_canonical_with_migration)"

CANONICAL_EQUAL_CODEX="$(new_project canonical-equal-codex)"
write_state "$CANONICAL_EQUAL_CODEX" SCV.md "shared-state"
write_state "$CANONICAL_EQUAL_CODEX" CODEX.md "shared-state"
assert_read_case canonical-equal-codex "$CANONICAL_EQUAL_CODEX" 0 \
  "$(expected_canonical_with_migration)"

CANONICAL_EQUAL_BOTH="$(new_project canonical-equal-both)"
write_state "$CANONICAL_EQUAL_BOTH" SCV.md "shared-state"
write_state "$CANONICAL_EQUAL_BOTH" CLAUDE.md "shared-state"
write_state "$CANONICAL_EQUAL_BOTH" CODEX.md "shared-state"
assert_read_case canonical-equal-both "$CANONICAL_EQUAL_BOTH" 0 \
  "$(expected_canonical_with_migration)"

CANONICAL_DIFF_CLAUDE="$(new_project canonical-diff-claude)"
write_state "$CANONICAL_DIFF_CLAUDE" SCV.md "canonical-state"
write_state "$CANONICAL_DIFF_CLAUDE" CLAUDE.md "claude-state"
assert_read_case canonical-diff-claude "$CANONICAL_DIFF_CLAUDE" 4 "$(cat <<'EOF'
STATE_INDEX_CONFLICT:
  scv/SCV.md <> scv/CLAUDE.md
STATE_INDEX: canonical
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: yes
MIGRATION_REQUIRED: reconcile the listed state indexes explicitly; no file was overwritten
EOF
)"

CANONICAL_DIFF_CODEX="$(new_project canonical-diff-codex)"
write_state "$CANONICAL_DIFF_CODEX" SCV.md "canonical-state"
write_state "$CANONICAL_DIFF_CODEX" CODEX.md "codex-state"
assert_read_case canonical-diff-codex "$CANONICAL_DIFF_CODEX" 4 "$(cat <<'EOF'
STATE_INDEX_CONFLICT:
  scv/SCV.md <> scv/CODEX.md
STATE_INDEX: canonical
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: yes
MIGRATION_REQUIRED: reconcile the listed state indexes explicitly; no file was overwritten
EOF
)"

CANONICAL_DIFF_BOTH="$(new_project canonical-diff-both)"
write_state "$CANONICAL_DIFF_BOTH" SCV.md "canonical-state"
write_state "$CANONICAL_DIFF_BOTH" CLAUDE.md "claude-state"
write_state "$CANONICAL_DIFF_BOTH" CODEX.md "codex-state"
assert_read_case canonical-diff-both "$CANONICAL_DIFF_BOTH" 4 "$(cat <<'EOF'
STATE_INDEX_CONFLICT:
  scv/SCV.md <> scv/CLAUDE.md
  scv/SCV.md <> scv/CODEX.md
STATE_INDEX: canonical
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: yes
MIGRATION_REQUIRED: reconcile the listed state indexes explicitly; no file was overwritten
EOF
)"

NO_PROMOTE="$(new_project no-promote no)"
write_state "$NO_PROMOTE" SCV.md "shared-state"
assert_read_case no-promote "$NO_PROMOTE" 0 "$(expected_canonical no)"

EXACT_POINTER="$(new_project canonical-pointer)"
write_state "$EXACT_POINTER" SCV.md "shared-state"
write_pointer "$EXACT_POINTER" CLAUDE.md
assert_read_case canonical-pointer "$EXACT_POINTER" 0 "$(expected_canonical)"

SIMILAR_MARKER="$(new_project similar-marker)"
write_state "$SIMILAR_MARKER" SCV.md "shared-state"
write_state "$SIMILAR_MARKER" CLAUDE.md \
  $'# SCV host compatibility pointer\n<!-- SCV:HOST-POINTER target=SCV.md --> trailing\n'
assert_read_case similar-marker "$SIMILAR_MARKER" 4 "$(cat <<'EOF'
STATE_INDEX_CONFLICT:
  scv/SCV.md <> scv/CLAUDE.md
STATE_INDEX: canonical
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: yes
MIGRATION_REQUIRED: reconcile the listed state indexes explicitly; no file was overwritten
EOF
)"

HEADER_ONLY="$(new_project header-only)"
write_state "$HEADER_ONLY" CLAUDE.md $'# SCV host compatibility pointer\nordinary legacy state\n'
assert_read_case header-only "$HEADER_ONLY" 0 "$(expected_legacy CLAUDE.md)"

ACTIVE_BROKEN="$(new_project active-broken)"
write_pointer "$ACTIVE_BROKEN" CLAUDE.md
write_state "$ACTIVE_BROKEN" CODEX.md "active-state"
assert_read_case active-broken "$ACTIVE_BROKEN" 4 "$(cat <<'EOF'
STATE_INDEX_BROKEN_POINTER:
  scv/CLAUDE.md -> scv/SCV.md (missing)
STATE_INDEX: legacy
STATE_INDEX_FILE: scv/CODEX.md
HYDRATED: yes
MIGRATION_REQUIRED: reconcile the listed state indexes explicitly; no file was overwritten
EOF
)"

POINTER_ONLY="$(new_project pointer-only)"
write_pointer "$POINTER_ONLY" CLAUDE.md
assert_read_case pointer-only "$POINTER_ONLY" 4 "$(cat <<'EOF'
STATE_INDEX_BROKEN_POINTER:
  scv/CLAUDE.md -> scv/SCV.md (missing)
STATE_INDEX: missing
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: no
MIGRATION_REQUIRED: reconcile the listed state indexes explicitly; no file was overwritten
EOF
)"

# Every dry-run path is mutation-free, including conflict and broken-pointer
# failures. Both profiles must return byte-identical diagnostics.
dry_run_cases=(
  "$EMPTY_ROOT" "$EMPTY" "$CANONICAL" "$CLAUDE_ONLY" "$CODEX_ONLY"
  "$EQUAL_DUAL" "$DIVERGENT_DUAL" "$CANONICAL_EQUAL_BOTH"
  "$CANONICAL_DIFF_BOTH" "$NO_PROMOTE" "$EXACT_POINTER"
  "$SIMILAR_MARKER" "$ACTIVE_BROKEN" "$POINTER_ONLY"
)
for project in "${dry_run_cases[@]}"; do
  before="$(snapshot "$project")"
  run_state_index "$CLAUDE_PROFILE" "$project" --migrate --dry-run
  claude_out="$RUN_OUTPUT"
  claude_rc="$RUN_RC"
  after="$(snapshot "$project")"
  assert_eq "$before" "$after" "$(basename "$project"): Claude dry-run mutation"

  run_state_index "$CODEX_PROFILE" "$project" --migrate --dry-run
  final="$(snapshot "$project")"
  assert_eq "$after" "$final" "$(basename "$project"): Codex dry-run mutation"
  assert_eq "$claude_rc" "$RUN_RC" "$(basename "$project"): dry-run return-code drift"
  assert_eq "$claude_out" "$RUN_OUTPUT" "$(basename "$project"): dry-run output drift"
done

# Stabilize backup paths so apply-mode output can be compared exactly across
# host profiles and independent project copies.
FAKE_BIN="$TMP/fake-bin"
mkdir -p "$FAKE_BIN"
REAL_DATE="$(command -v date)"
cat > "$FAKE_BIN/date" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "+%Y%m%d-%H%M%S" ]]; then
  echo 20260729-120000
else
  exec "$REAL_DATE" "\$@"
fi
EOF
chmod +x "$FAKE_BIN/date"
ORIGINAL_PATH="$PATH"
export PATH="$FAKE_BIN:$PATH"

clone_project() {
  local source="$1" target="$2"
  mkdir -p "$(dirname "$target")"
  cp -R "$source" "$target"
}

run_apply_pair() {
  local label="$1" source="$2"
  shift 2
  APPLY_CLAUDE="$TMP/apply/$label-claude"
  APPLY_CODEX="$TMP/apply/$label-codex"
  clone_project "$source" "$APPLY_CLAUDE"
  clone_project "$source" "$APPLY_CODEX"

  run_state_index "$CLAUDE_PROFILE" "$APPLY_CLAUDE" --migrate "$@"
  local claude_out="$RUN_OUTPUT" claude_rc="$RUN_RC"
  run_state_index "$CODEX_PROFILE" "$APPLY_CODEX" --migrate "$@"
  assert_eq "$claude_rc" "$RUN_RC" "$label: apply return-code drift"
  local normalized_claude normalized_codex
  normalized_claude="$(
    sed -E 's/shared-core-migration-[0-9]+/shared-core-migration-<pid>/g' \
      <<<"$claude_out"
  )"
  normalized_codex="$(
    sed -E 's/shared-core-migration-[0-9]+/shared-core-migration-<pid>/g' \
      <<<"$RUN_OUTPUT"
  )"
  assert_eq "$normalized_claude" "$normalized_codex" \
    "$label: apply output semantic drift"
  APPLY_OUTPUT="$normalized_codex"
  APPLY_RC="$RUN_RC"
}

backup_dir() {
  local project="$1" matches
  matches="$(
    find "$project/.scv-backup/20260729-120000" -mindepth 1 -maxdepth 1 \
      -type d -name 'shared-core-migration-*' -print
  )"
  [[ -n "$matches" && "$matches" != *$'\n'* ]] \
    || fail "expected exactly one migration backup under $project"
  printf '%s\n' "$matches"
}

APPLY_SINGLE_SOURCE="$(new_project apply-single-codex)"
write_state "$APPLY_SINGLE_SOURCE" CODEX.md $'shared-state\nwith-second-line\n' 640
cp "$APPLY_SINGLE_SOURCE/scv/CODEX.md" "$TMP/apply-single-original"
original_mode="$(stat_mode "$APPLY_SINGLE_SOURCE/scv/CODEX.md")"
run_apply_pair single-codex "$APPLY_SINGLE_SOURCE"
assert_eq 0 "$APPLY_RC" "single CODEX migration return code"
assert_eq "$(cat <<'EOF'
MIGRATED: scv/CODEX.md -> scv/SCV.md
POINTERED: scv/CODEX.md -> scv/SCV.md
LEGACY_STATE_BACKUP: .scv-backup/20260729-120000/shared-core-migration-<pid>
STATE_INDEX: canonical
STATE_INDEX_FILE: scv/SCV.md
HYDRATED: yes
MIGRATION_COMPLETE: yes
EOF
)" "$APPLY_OUTPUT" "single CODEX exact apply output"
for project in "$APPLY_CLAUDE" "$APPLY_CODEX"; do
  backup="$(backup_dir "$project")"
  cmp "$TMP/apply-single-original" "$project/scv/SCV.md" \
    || fail "single migration changed canonical bytes"
  cmp "$TMP/apply-single-original" "$backup/CODEX.md" \
    || fail "single migration changed backup bytes"
  assert_eq "$original_mode" "$(stat_mode "$project/scv/SCV.md")" \
    "single migration canonical mode"
  assert_eq "$original_mode" "$(stat_mode "$backup/CODEX.md")" \
    "single migration backup mode"
  assert_eq "$original_mode" "$(stat_mode "$project/scv/CODEX.md")" \
    "single migration pointer mode"
  grep -qxF '<!-- SCV:HOST-POINTER target=SCV.md -->' "$project/scv/CODEX.md" \
    || fail "single migration pointer lacks exact marker"
  [[ ! -e "$project/scv/CLAUDE.md" ]] \
    || fail "single migration manufactured the other host's legacy file"
done

APPLY_DUAL_SOURCE="$(new_project apply-equal-dual)"
write_state "$APPLY_DUAL_SOURCE" CLAUDE.md $'shared-dual\n' 600
write_state "$APPLY_DUAL_SOURCE" CODEX.md $'shared-dual\n' 640
cp "$APPLY_DUAL_SOURCE/scv/CLAUDE.md" "$TMP/apply-dual-original"
run_apply_pair equal-dual "$APPLY_DUAL_SOURCE"
assert_eq 0 "$APPLY_RC" "equal dual migration return code"
for project in "$APPLY_CLAUDE" "$APPLY_CODEX"; do
  backup="$(backup_dir "$project")"
  cmp "$TMP/apply-dual-original" "$project/scv/SCV.md" \
    || fail "dual migration changed canonical bytes"
  for name in CLAUDE.md CODEX.md; do
    cmp "$TMP/apply-dual-original" "$backup/$name" \
      || fail "dual migration changed $name backup bytes"
    grep -qxF '<!-- SCV:HOST-POINTER target=SCV.md -->' "$project/scv/$name" \
      || fail "dual migration did not pointerize $name"
  done
  assert_eq 600 "$(stat_mode "$project/scv/CLAUDE.md")" \
    "dual migration CLAUDE pointer mode"
  assert_eq 640 "$(stat_mode "$project/scv/CODEX.md")" \
    "dual migration CODEX pointer mode"
done

APPLY_CANONICAL_SOURCE="$(new_project apply-canonical-equal)"
write_state "$APPLY_CANONICAL_SOURCE" SCV.md $'canonical-shared\n' 644
write_state "$APPLY_CANONICAL_SOURCE" CLAUDE.md $'canonical-shared\n' 600
cp "$APPLY_CANONICAL_SOURCE/scv/SCV.md" "$TMP/apply-canonical-original"
run_apply_pair canonical-equal "$APPLY_CANONICAL_SOURCE"
assert_eq 0 "$APPLY_RC" "canonical+equal migration return code"
for project in "$APPLY_CLAUDE" "$APPLY_CODEX"; do
  cmp "$TMP/apply-canonical-original" "$project/scv/SCV.md" \
    || fail "canonical+equal migration changed canonical state"
  grep -qxF '<!-- SCV:HOST-POINTER target=SCV.md -->' "$project/scv/CLAUDE.md" \
    || fail "canonical+equal migration did not pointerize active legacy"
  [[ ! -e "$project/scv/CODEX.md" ]] \
    || fail "canonical+equal migration manufactured CODEX.md"
done

# A normal divergent apply must fail before creating a backup or changing any
# state file.
before="$(snapshot "$CANONICAL_DIFF_BOTH")"
run_state_index "$CLAUDE_PROFILE" "$CANONICAL_DIFF_BOTH" --migrate
assert_eq 4 "$RUN_RC" "divergent apply return code"
after="$(snapshot "$CANONICAL_DIFF_BOTH")"
assert_eq "$before" "$after" "divergent apply changed project"

# After Core sync advances canonical state, mutually equal legacy indexes may
# be finalized. The canonical bytes remain authoritative.
POST_SYNC_SOURCE="$(new_project post-sync)"
write_state "$POST_SYNC_SOURCE" SCV.md $'advanced-canonical\n' 644
write_state "$POST_SYNC_SOURCE" CLAUDE.md $'pre-sync-state\n' 600
write_state "$POST_SYNC_SOURCE" CODEX.md $'pre-sync-state\n' 640
cp "$POST_SYNC_SOURCE/scv/SCV.md" "$TMP/post-sync-canonical"
cp "$POST_SYNC_SOURCE/scv/CLAUDE.md" "$TMP/post-sync-legacy"
run_apply_pair post-sync "$POST_SYNC_SOURCE" --core-sync-succeeded
assert_eq 0 "$APPLY_RC" "post-sync finalization return code"
for project in "$APPLY_CLAUDE" "$APPLY_CODEX"; do
  backup="$(backup_dir "$project")"
  cmp "$TMP/post-sync-canonical" "$project/scv/SCV.md" \
    || fail "post-sync finalizer changed authoritative canonical state"
  for name in CLAUDE.md CODEX.md; do
    cmp "$TMP/post-sync-legacy" "$backup/$name" \
      || fail "post-sync finalizer changed $name backup"
    grep -qxF '<!-- SCV:HOST-POINTER target=SCV.md -->' "$project/scv/$name" \
      || fail "post-sync finalizer did not pointerize $name"
  done
done

# Deterministically inject races immediately after Core's copy operation.
# Correct implementations must revalidate the source and use no-replace
# canonical installation rather than silently overwriting concurrent state.
REAL_CP="$(command -v cp)"
cat > "$FAKE_BIN/cp" <<EOF
#!/usr/bin/env bash
set -euo pipefail
"$REAL_CP" "\$@"
destination="\${!#}"
case "\${SCV_STATE_INDEX_RACE_MODE:-}" in
  legacy)
    if [[ "\$destination" == */shared-core-migration-*/CODEX.md && ! -e "\$SCV_STATE_INDEX_RACE_ONCE" ]]; then
      : > "\$SCV_STATE_INDEX_RACE_ONCE"
      printf '%s\n' 'concurrent-legacy-change' >> "\$SCV_STATE_INDEX_RACE_TARGET"
    fi
    ;;
  canonical)
    if [[ "\$destination" == *.scv-migration.* && ! -e "\$SCV_STATE_INDEX_RACE_ONCE" ]]; then
      : > "\$SCV_STATE_INDEX_RACE_ONCE"
      printf '%s\n' 'concurrent-canonical-state' > "\$SCV_STATE_INDEX_RACE_TARGET"
    fi
    ;;
esac
EOF
chmod +x "$FAKE_BIN/cp"

RACE_LEGACY="$(new_project race-legacy)"
write_state "$RACE_LEGACY" SCV.md $'advanced-canonical\n'
write_state "$RACE_LEGACY" CODEX.md $'pre-sync-state\n'
race_once="$TMP/race-legacy-once"
set +e
race_output="$(
  SCV_STATE_INDEX_RACE_MODE=legacy \
  SCV_STATE_INDEX_RACE_ONCE="$race_once" \
  SCV_STATE_INDEX_RACE_TARGET="$RACE_LEGACY/scv/CODEX.md" \
  SCV_HOST_PROFILE="$CODEX_PROFILE" \
    bash "$STATE_INDEX" --project-dir "$RACE_LEGACY" \
      --migrate --core-sync-succeeded 2>&1
)"
race_rc=$?
set -e
[[ $race_rc -ne 0 ]] || fail "post-sync legacy race was silently pointerized"
grep -qF 'concurrent-legacy-change' "$RACE_LEGACY/scv/CODEX.md" \
  || fail "legacy race fixture did not run"
! grep -qxF '<!-- SCV:HOST-POINTER target=SCV.md -->' "$RACE_LEGACY/scv/CODEX.md" \
  || fail "post-sync race overwrote concurrently changed legacy state"
[[ "$race_output" == *"changed"* || "$race_output" == *"race"* ]] \
  || fail "post-sync race did not report why finalization stopped"

RACE_CANONICAL="$(new_project race-canonical)"
write_state "$RACE_CANONICAL" CODEX.md $'legacy-seed\n'
race_once="$TMP/race-canonical-once"
set +e
race_output="$(
  SCV_STATE_INDEX_RACE_MODE=canonical \
  SCV_STATE_INDEX_RACE_ONCE="$race_once" \
  SCV_STATE_INDEX_RACE_TARGET="$RACE_CANONICAL/scv/SCV.md" \
  SCV_HOST_PROFILE="$CODEX_PROFILE" \
    bash "$STATE_INDEX" --project-dir "$RACE_CANONICAL" --migrate 2>&1
)"
race_rc=$?
set -e
[[ $race_rc -ne 0 ]] || fail "canonical creation race overwrote concurrent state"
assert_eq "concurrent-canonical-state" \
  "$(tr -d '\n' < "$RACE_CANONICAL/scv/SCV.md")" \
  "canonical creation must be atomic no-replace"
! grep -qxF '<!-- SCV:HOST-POINTER target=SCV.md -->' "$RACE_CANONICAL/scv/CODEX.md" \
  || fail "canonical race pointerized the legacy source"

rm -f "$FAKE_BIN/cp"
export PATH="$FAKE_BIN:$ORIGINAL_PATH"

# Migrate with one profile and inspect with the other. Then repeat in the
# reverse direction. Both round trips must converge on the same canonical
# output and universal pointer marker.
round_trip() {
  local label="$1" migrate_profile="$2" inspect_profile="$3" legacy_name="$4"
  local project
  project="$(new_project "$label")"
  write_state "$project" "$legacy_name" $'round-trip-state\n'

  run_state_index "$migrate_profile" "$project" --migrate
  assert_eq 0 "$RUN_RC" "$label: migration return code"
  grep -qxF '<!-- SCV:HOST-POINTER target=SCV.md -->' "$project/scv/$legacy_name" \
    || fail "$label: migration did not write the universal marker"

  run_state_index "$inspect_profile" "$project"
  assert_eq 0 "$RUN_RC" "$label: opposite-host inspection return code"
  assert_eq "$(expected_canonical)" "$RUN_OUTPUT" \
    "$label: opposite host did not resolve canonical state"

  run_state_index "$migrate_profile" "$project"
  assert_eq "$(expected_canonical)" "$RUN_OUTPUT" \
    "$label: originating host disagreed after migration"

  rm "$project/scv/SCV.md"
  before="$(snapshot "$project")"
  run_state_index "$migrate_profile" "$project"
  local first_out="$RUN_OUTPUT" first_rc="$RUN_RC"
  after="$(snapshot "$project")"
  assert_eq "$before" "$after" "$label: originating broken-pointer inspect mutated"
  run_state_index "$inspect_profile" "$project"
  assert_eq "$first_rc" "$RUN_RC" "$label: broken-pointer return-code drift"
  assert_eq "$first_out" "$RUN_OUTPUT" "$label: broken-pointer output drift"
  assert_eq 4 "$RUN_RC" "$label: broken pointer must fail read-only"
  grep -qF 'STATE_INDEX_BROKEN_POINTER:' <<<"$RUN_OUTPUT" \
    || fail "$label: broken pointer was not diagnosed"
}

round_trip claude-to-codex "$CLAUDE_PROFILE" "$CODEX_PROFILE" CLAUDE.md
round_trip codex-to-claude "$CODEX_PROFILE" "$CLAUDE_PROFILE" CODEX.md

echo "shared state-index matrix, migration, race, and cross-host round trips: ok"
