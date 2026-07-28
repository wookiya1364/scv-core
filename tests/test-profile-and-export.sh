#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[[ ! -e "$ROOT/core-manifest.json" && ! -e "$ROOT/SHA256SUMS" ]] || {
  echo "source checkout contains export-only integrity metadata" >&2
  exit 1
}

PROFILE="$TMP/quoted.env"
cat > "$PROFILE" <<'EOF'
SCV_HOST_PROFILE_API=1
SCV_HOST_ID=fixture-host
SCV_HOST_LABEL='Fixture Agent'
SCV_ACTION_TEMPLATE='$scv:{action}'
SCV_ARGUMENT_STYLE=template-string
SCV_STATE_INDEX=SCV.md
SCV_LEGACY_STATE_INDEXES='CLAUDE.md|CODEX.md'
SCV_ROOT_ENV=FIXTURE_PLUGIN_ROOT
SCV_GRAPH_SKILL_PATHS='$HOME/.fixture/graph/SKILL.md'
SCV_UPDATE_OWNER=adapter
SCV_MODEL_POLICY_OWNER=adapter
EOF

"$ROOT/tools/validate-host-profile.sh" --profile "$PROFILE" >/dev/null
"$ROOT/tools/vendor-core.sh" \
  --source "$ROOT" \
  --target "$TMP/vendor/scv-core" \
  --profile "$PROFILE" >/dev/null

VENDOR="$TMP/vendor/scv-core"
"$VENDOR/tools/verify-core.sh" --root "$VENDOR" >/dev/null
grep -qF '$scv:help' "$VENDOR/core/protocols/help.md"
grep -qF '$ARGUMENTS' "$VENDOR/core/protocols/help.md"
grep -qF 'SCV_ACTION_TEMPLATE=$scv:{action}' "$VENDOR/core/host-profile.env"
grep -qF '"artifact_sha256": null' "$VENDOR/core.lock.json"

ARTIFACT_HASH='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
"$ROOT/tools/vendor-core.sh" \
  --source "$ROOT" \
  --target "$TMP/vendor-with-artifact/scv-core" \
  --profile "$PROFILE" \
  --artifact-sha256 "$ARTIFACT_HASH" >/dev/null
grep -qF "\"artifact_sha256\": \"$ARTIFACT_HASH\"" \
  "$TMP/vendor-with-artifact/scv-core/core.lock.json"

# A linked worktree has a .git file rather than a .git directory. Build a tiny
# committed source repo from the current export so this test does not depend on
# whether the developer's working branch has already been committed.
"$ROOT/tools/export-core.sh" --output "$TMP/source-repo" >/dev/null
ln -s "$TMP/source-repo" "$TMP/source-repo-alias"
"$TMP/source-repo/tools/verify-core.sh" \
  --root "$TMP/source-repo-alias" >/dev/null
if find "$TMP/source-repo" -type d \
  \( -name node_modules -o -name dist -o -name dist-deck -o -name coverage -o -name .vite -o -name .cache \) \
  -print -quit | grep -q .; then
  echo "export leaked a development directory" >&2
  exit 1
fi
[[ -f "$TMP/source-repo/core/DeckUI/src/deck/decks/demo-prd/deck.json" ]]
[[ -f "$TMP/source-repo/core/DeckUI/src/deck/decks/refund/deck.json" ]]
[[ ! -e "$TMP/source-repo/core/DeckUI/src/deck/decks/ai-tm-center-deck/deck.json" ]]
[[ ! -e "$TMP/source-repo/core/DeckUI/src/deck/decks/fidelity-probe/deck.json" ]]
if find "$TMP/source-repo" -type l -exec test -d {} \; -print -quit | grep -q .; then
  echo "export contains a directory symlink" >&2
  exit 1
fi
git -C "$TMP/source-repo" init -q -b main
git -C "$TMP/source-repo" config user.email fixture@example.invalid
git -C "$TMP/source-repo" config user.name fixture
git -C "$TMP/source-repo" add .
git -C "$TMP/source-repo" commit -qm "fixture"
git -C "$TMP/source-repo" worktree add --detach "$TMP/worktree" HEAD >/dev/null
trap 'git -C "$TMP/source-repo" worktree remove --force "$TMP/worktree" >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT
mkdir -p \
  "$TMP/worktree/core/DeckUI/node_modules/pkg" \
  "$TMP/worktree/core/DeckUI/dist" \
  "$TMP/worktree/core/DeckUI/dist-deck" \
  "$TMP/worktree/core/DeckUI/.vite" \
  "$TMP/worktree/core/DeckUI/coverage" \
  "$TMP/worktree/core/DeckUI/.cache"
printf 'fixture\n' > "$TMP/worktree/core/DeckUI/node_modules/pkg/index.js"
mkdir -p "$TMP/worktree/core/DeckUI/src/deck/decks/generated-fixture"
printf '{"generated":true}\n' \
  > "$TMP/worktree/core/DeckUI/src/deck/decks/generated-fixture/deck.json"
ln -s pkg "$TMP/worktree/core/DeckUI/node_modules/pkg-link"
"$ROOT/tools/vendor-core.sh" \
  --source "$TMP/worktree" \
  --target "$TMP/from-worktree/scv-core" \
  --profile "$PROFILE" >/dev/null
"$TMP/from-worktree/scv-core/tools/verify-core.sh" \
  --root "$TMP/from-worktree/scv-core" >/dev/null
if find "$TMP/from-worktree/scv-core" -type d \
  \( -name node_modules -o -name dist -o -name dist-deck -o -name coverage -o -name .vite -o -name .cache \) \
  -print -quit | grep -q .; then
  echo "vendored payload leaked a development directory" >&2
  exit 1
fi
[[ ! -e "$TMP/from-worktree/scv-core/core/DeckUI/src/deck/decks/generated-fixture/deck.json" ]]
if find "$TMP/from-worktree/scv-core" -type l -exec test -d {} \; -print -quit | grep -q .; then
  echo "vendored payload contains a directory symlink" >&2
  exit 1
fi
git -C "$TMP/source-repo" worktree remove --force "$TMP/worktree" >/dev/null

[[ ! -e "$ROOT/core-manifest.json" && ! -e "$ROOT/SHA256SUMS" ]] || {
  echo "export or vendoring dirtied the source checkout" >&2
  exit 1
}

echo "profile, export, vendoring, and worktree source: ok"
