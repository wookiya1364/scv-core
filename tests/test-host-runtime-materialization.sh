#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

tree_snapshot() {
  local root="$1"
  (
    cd "$root"
    find . -mindepth 1 -print | LC_ALL=C sort
    while IFS= read -r file; do
      cksum "$file"
    done < <(find . -type f | LC_ALL=C sort)
  )
}

assert_hydrate_root_is_pure() {
  local project="$1"
  local unexpected
  unexpected="$(
    find "$project" -mindepth 1 -maxdepth 1 \
      ! -name scv ! -name .env.example.scv ! -name .gitignore -print
  )"
  [[ -z "$unexpected" ]] || {
    echo "hydrate leaked unexpected project-root entries: $unexpected" >&2
    return 1
  }
}

exercise_profile() {
  local host="$1"
  local profile="$2"
  local legacy_index="$3"
  local expected_action="$4"
  local vendor="$TMP/$host/vendor/scv-core"
  local core="$vendor/core"
  local project="$TMP/$host/project"
  local output before after argument

  "$ROOT/tools/vendor-core.sh" \
    --source "$ROOT" \
    --target "$vendor" \
    --profile "$profile" >/dev/null

  mkdir -p "$project"
  output="$(bash "$core/scripts/hydrate.sh" init "$project")"
  grep -qF "$expected_action" <<< "$output"
  assert_hydrate_root_is_pure "$project"
  tree_snapshot "$project" > "$TMP/$host-hydrate.snapshot"

  mv "$project/scv/SCV.md" "$project/scv/$legacy_index"

  before="$(tree_snapshot "$project")"
  output="$(cd "$project" && bash "$core/scripts/help.sh")"
  after="$(tree_snapshot "$project")"
  [[ "$before" == "$after" ]]
  grep -qF "ARG_CONVERSATION:" <<< "$output"
  grep -qF "$expected_action" <<< "$output"

  arguments=(
    'build a refund button'
    'literal $(touch SHOULD_NOT_EXIST); $HOME ! * ? "quoted" and `backticks`'
    $'first line\n__SCV_HELP_ARG_EOF__\nsecond line; touch SHOULD_NOT_EXIST'
  )
  for argument in "${arguments[@]}"; do
    before="$(tree_snapshot "$project")"
    output="$(cd "$project" && bash "$core/scripts/help.sh" "$argument")"
    after="$(tree_snapshot "$project")"
    [[ "$before" == "$after" ]] || {
      echo "$host help mutated a legacy-only project for argument: $argument" >&2
      return 1
    }
    grep -qF "ARG_CONTEXT: provided" <<< "$output"
    [[ ! -e "$project/SHOULD_NOT_EXIST" ]]
    [[ ! -e "$project/scv/.conversations" ]]
  done

  (cd "$project" && bash "$core/scripts/status.sh" >/dev/null)
  output="$(cd "$project" && bash "$core/scripts/workspace-helper.sh" info)"
  grep -qF "MODE: SINGLE" <<< "$output"
}

exercise_profile \
  claude-code \
  "$ROOT/tests/fixtures/claude-code.env" \
  CLAUDE.md \
  /scv:help

CLAUDE_HELP="$TMP/claude-code/vendor/scv-core/core/protocols/help.md"
grep -qF '$ARGUMENTS' "$CLAUDE_HELP"
grep -qF 'untrusted prompt data, never shell source' "$CLAUDE_HELP"
grep -qF 'exactly one' "$CLAUDE_HELP"
grep -qF '`SCV_ARGS` element' "$CLAUDE_HELP"
grep -qF -- '--with-context' "$CLAUDE_HELP"
if grep -R -n '^```!$' "$TMP/claude-code/vendor/scv-core/core/protocols" >/dev/null 2>&1; then
  echo "template-string projection retained a dynamic shell fence" >&2
  exit 1
fi

# Simulate raw Claude text substitution, including the former heredoc delimiter,
# newlines, quotes, substitutions, globbing, backticks, and a command sentinel.
# None of it may enter an existing Bash example.
CLAUDE_SUBSTITUTED="$TMP/claude-help-substituted.md"
python3 - "$CLAUDE_HELP" "$CLAUDE_SUBSTITUTED" <<'PY'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1]).read_text()
argument = """first 'single' and "double"
__SCV_HELP_ARG_EOF__
$(touch CLAUDE_INJECTION); `touch CLAUDE_BACKTICK`; $HOME * ?
last line"""
substituted = source.replace("$ARGUMENTS", argument)
blocks = re.findall(r"```(?:bash)?\n(.*?)\n```", substituted, re.S)
for block in blocks:
    if "CLAUDE_INJECTION" in block or "CLAUDE_BACKTICK" in block:
        raise SystemExit("raw host argument entered a shell example")
if substituted.count(argument) != 1:
    raise SystemExit("raw host argument was not preserved exactly once as prompt data")
pathlib.Path(sys.argv[2]).write_text(substituted)
PY
CLAUDE_PROJECT="$TMP/claude-code/project"
CLAUDE_CORE="$TMP/claude-code/vendor/scv-core/core"
CLAUDE_BEFORE="$(tree_snapshot "$CLAUDE_PROJECT")"
CLAUDE_OUTPUT="$(
  cd "$CLAUDE_PROJECT"
  CLAUDE_PLUGIN_ROOT="$CLAUDE_CORE" bash "$CLAUDE_CORE/scripts/help.sh" --with-context
)"
CLAUDE_AFTER="$(tree_snapshot "$CLAUDE_PROJECT")"
[[ "$CLAUDE_BEFORE" == "$CLAUDE_AFTER" ]]
grep -qF 'ARG_CONTEXT: provided' <<< "$CLAUDE_OUTPUT"
[[ ! -e "$CLAUDE_PROJECT/CLAUDE_INJECTION" ]]
[[ ! -e "$CLAUDE_PROJECT/CLAUDE_BACKTICK" ]]

exercise_profile \
  codex \
  "$ROOT/tests/fixtures/codex.env" \
  CODEX.md \
  '$scv:help'

CODEX_CORE="$TMP/codex/vendor/scv-core/core"
grep -qF 'scv=' "$CODEX_CORE/scripts/help.sh"
grep -qF '$scv' "$CODEX_CORE/scripts/help.sh"
grep -qF -- '--with-context' "$CODEX_CORE/protocols/help.md"
if rg -n 'unbound variable' "$TMP/codex" >/dev/null 2>&1; then
  echo "Codex materialized runtime produced an unbound variable" >&2
  exit 1
fi

diff -u "$TMP/claude-code-hydrate.snapshot" "$TMP/codex-hydrate.snapshot"
diff -ru \
  "$TMP/claude-code/vendor/scv-core/core/template" \
  "$TMP/codex/vendor/scv-core/core/template"

echo "real Claude/Codex profile runtime materialization: ok"
