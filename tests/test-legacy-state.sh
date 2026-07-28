#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE="$ROOT/core"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROFILE="$TMP/profile.env"
cat > "$PROFILE" <<'EOF'
SCV_HOST_PROFILE_API=1
SCV_HOST_ID=transition-fixture
SCV_HOST_LABEL=Fixture Agent
SCV_ACTION_TEMPLATE=action:{action}
SCV_ARGUMENT_STYLE=argv-array
SCV_STATE_INDEX=SCV.md
SCV_LEGACY_STATE_INDEXES=CLAUDE.md|CODEX.md
SCV_ROOT_ENV=SCV_CORE_ROOT
SCV_GRAPH_SKILL_PATHS=
SCV_UPDATE_OWNER=adapter
SCV_MODEL_POLICY_OWNER=adapter
EOF

project_with_legacy() {
  local project="$1" legacy="$2"
  mkdir -p "$project/scv/raw"
  cp "$CORE/template/scv/SCV.md" "$project/scv/$legacy"
  cp "$CORE/template/scv/INTAKE.md" "$project/scv/INTAKE.md"
  cp "$CORE/template/scv/TESTING.md" "$project/scv/TESTING.md"
  cp "$CORE/template/scv/REPORTING.md" "$project/scv/REPORTING.md"
  perl -pi -e 's{^status: draft$}{status: N/A}' \
    "$project/scv/TESTING.md" "$project/scv/REPORTING.md"
  perl -0pi -e 's/(<!-- PROJECT:LOCAL START -->).*?(<!-- PROJECT:LOCAL END -->)/$1\nlegacy-local-value: keep-me\n$2/s' \
    "$project/scv/TESTING.md" "$project/scv/REPORTING.md"
  printf 'baseline\n' > "$project/scv/raw/existing.txt"
  local size mtime
  size="$(wc -c < "$project/scv/raw/existing.txt" | tr -d ' ')"
  mtime="$(date -u -r "$project/scv/raw/existing.txt" +%Y-%m-%dT%H:%M:%SZ)"
  cat > "$project/scv/readpath.json" <<EOF
{
  "version": 1,
  "updated_at": "2026-01-01T00:00:00Z",
  "files": {
    "scv/raw/existing.txt": {
      "size": $size,
      "mtime": "$mtime"
    }
  }
}
EOF
}

snapshot() {
  (cd "$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 cksum)
}

for legacy in CLAUDE.md CODEX.md; do
  project="$TMP/${legacy%.md}"
  project_with_legacy "$project" "$legacy"
  before="$(snapshot "$project")"
  out="$(cd "$project" && SCV_HOST_PROFILE="$PROFILE" bash "$CORE/scripts/help.sh")"
  after="$(snapshot "$project")"
  [[ "$before" == "$after" ]]
  grep -qF "hydrate complete (scv/$legacy + scv/INTAKE.md exist)" <<<"$out"
  ! grep -qF "This directory is not hydrated yet" <<<"$out"
  [[ ! -e "$project/scv/SCV.md" ]]

  status_out="$(cd "$project" && SCV_HOST_PROFILE="$PROFILE" bash "$CORE/scripts/status.sh")"
  grep -qF "no changes since last index" <<<"$status_out"
done

# Explicit sync performs a non-destructive one-time migration. Dry-run is
# mutation-free; apply preserves N/A status and local marker content.
MIGRATE="$TMP/migrate"
project_with_legacy "$MIGRATE" CLAUDE.md
before="$(snapshot "$MIGRATE")"
dry_out="$(SCV_HOST_PROFILE="$PROFILE" bash "$CORE/scripts/sync.sh" --project-dir "$MIGRATE" --dry-run)"
after="$(snapshot "$MIGRATE")"
[[ "$before" == "$after" ]]
grep -qF "MIGRATE" <<<"$dry_out"
SCV_HOST_PROFILE="$PROFILE" bash "$CORE/scripts/sync.sh" --project-dir "$MIGRATE" >/dev/null
[[ -f "$MIGRATE/scv/SCV.md" && -f "$MIGRATE/scv/CLAUDE.md" ]]
grep -q '^status: N/A$' "$MIGRATE/scv/TESTING.md"
grep -q '^status: N/A$' "$MIGRATE/scv/REPORTING.md"
grep -qF 'legacy-local-value: keep-me' "$MIGRATE/scv/TESTING.md"
grep -qF 'legacy-local-value: keep-me' "$MIGRATE/scv/REPORTING.md"

# Divergent active state files fail closed and remain byte-identical.
CONFLICT="$TMP/conflict"
project_with_legacy "$CONFLICT" CLAUDE.md
cp "$CORE/template/scv/SCV.md" "$CONFLICT/scv/SCV.md"
printf '\ncanonical-only\n' >> "$CONFLICT/scv/SCV.md"
before="$(snapshot "$CONFLICT")"
set +e
conflict_out="$(SCV_HOST_PROFILE="$PROFILE" bash "$CORE/scripts/sync.sh" --project-dir "$CONFLICT" --dry-run 2>&1)"
rc=$?
set -e
after="$(snapshot "$CONFLICT")"
[[ $rc -eq 3 && "$before" == "$after" ]]
grep -qF "state-index conflict" <<<"$conflict_out"

help_conflict="$(cd "$CONFLICT" && SCV_HOST_PROFILE="$PROFILE" bash "$CORE/scripts/help.sh")"
grep -qF "STATE_INDEX_CONFLICT:" <<<"$help_conflict"
grep -qF "hydrate complete" <<<"$help_conflict"
grep -qF "will not hydrate, sync, migrate" <<<"$help_conflict"

# A host pointer without its canonical target is not readable legacy state.
# Help remains read-only and sync fails before recreating SCV.md from pointer
# prose.
for legacy in CLAUDE.md CODEX.md; do
  BROKEN="$TMP/broken-${legacy%.md}"
  mkdir -p "$BROKEN/scv"
  cp "$CORE/template/scv/INTAKE.md" "$BROKEN/scv/INTAKE.md"
  printf '<!-- SCV:HOST-POINTER target=SCV.md -->\nRead scv/SCV.md.\n' \
    > "$BROKEN/scv/$legacy"
  before="$(snapshot "$BROKEN")"
  broken_help="$(cd "$BROKEN" && SCV_HOST_PROFILE="$PROFILE" bash "$CORE/scripts/help.sh" 'unsafe $(touch NEVER)')"
  after="$(snapshot "$BROKEN")"
  [[ "$before" == "$after" && ! -e "$BROKEN/NEVER" ]]
  grep -qF "STATE_INDEX_BROKEN_POINTER:" <<<"$broken_help"
  grep -qF "will not hydrate, sync, migrate" <<<"$broken_help"
  set +e
  broken_sync="$(
    SCV_HOST_PROFILE="$PROFILE" \
      bash "$CORE/scripts/sync.sh" --project-dir "$BROKEN" --dry-run 2>&1
  )"
  rc=$?
  set -e
  [[ $rc -eq 4 && ! -e "$BROKEN/scv/SCV.md" ]]
  grep -qF "pointer is broken" <<<"$broken_sync"
done

echo "legacy state transition, no-mutation help, and readpath compatibility: ok"
