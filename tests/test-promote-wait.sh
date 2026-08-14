#!/usr/bin/env bash
# The promote chain's merge gate, replayed against recorded PR states.
#
# This block has been wrong twice, both times in CI only, and both times the
# symptom was a promotion that half-completed and needed a hand-merge. A text
# assertion would not have caught either one: the first version read plausibly
# ("wait for checks to pass") and the second read more plausibly still ("wait
# for checks to exist"). What was wrong was the behaviour on one specific input
# — a skipped matrix placeholder that arrives before the real jobs — so the
# behaviour is what this file tests.
#
# It extracts the live block from .github/workflows/promote.yml between the
# await-mergeable markers and runs it with `gh` and `sleep` stubbed. Editing the
# workflow changes what this test executes; deleting the markers fails it.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WF="$ROOT/.github/workflows/promote.yml"

PASS=0; FAIL=0
pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; [[ $# -gt 1 ]] && printf '%s\n' "$2" | sed 's/^/      /'; FAIL=$((FAIL+1)); }

command -v python3 >/dev/null 2>&1 || { echo "  ✓ (skip) python3 unavailable"; exit 0; }
command -v jq      >/dev/null 2>&1 || { echo "  ✓ (skip) jq unavailable"; exit 0; }
[[ -f "$WF" ]] || { echo "missing $WF" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---- extract the live block ------------------------------------------------
python3 - "$WF" "$TMP/block.sh" <<'PY'
import sys, yaml
wf, out = sys.argv[1], sys.argv[2]
d = yaml.safe_load(open(wf))
runs = "\n".join(s["run"] for j in d["jobs"].values()
                 for s in j.get("steps", []) if "run" in s)
try:
    i = runs.index("# >>> await-mergeable")
    k = runs.index("# <<< await-mergeable")
except ValueError:
    sys.stderr.write("await-mergeable markers not found in promote.yml\n")
    sys.exit(2)
open(out, "w").write(runs[i:k])
PY
if [[ $? -ne 0 ]]; then
  fail "[0] could not slice the await-mergeable block out of promote.yml"
  echo; echo "  passed: $PASS  failed: $FAIL"; exit 1
fi
lines="$(wc -l <"$TMP/block.sh" | tr -d ' ')"
if (( lines > 25 )); then
  pass "[0] sliced the live block from promote.yml ($lines lines)"
else
  fail "[0] the sliced block is implausibly short ($lines lines) — markers likely moved"
fi

# ---- stubs -----------------------------------------------------------------
# Each `gh pr view` call consumes the next fixture line. That models a PR whose
# state advances while the loop watches it, which is the whole point: a fixture
# that never changes cannot distinguish "waited correctly" from "gave up".
mkdir -p "$TMP/bin"
cat >"$TMP/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "pr view")
    n=$(cat "$FIXTURE_CURSOR" 2>/dev/null || echo 1)
    total=$(wc -l <"$FIXTURE_FILE")
    [ "$n" -gt "$total" ] && n="$total"          # hold on the last state
    sed -n "${n}p" "$FIXTURE_FILE"
    echo $((n + 1)) >"$FIXTURE_CURSOR"
    ;;
  "pr update-branch") echo "update-branch" >>"$CALL_LOG" ;;
  *) : ;;
esac
exit 0
STUB
chmod +x "$TMP/bin/gh"
# The real block sleeps 10s per turn and waits up to 900s. Replaying that
# honestly would take fifteen minutes per scenario, so time is stubbed — the
# loop's arithmetic is unchanged, only its cost.
cat >"$TMP/bin/sleep" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$TMP/bin/sleep"
export PATH="$TMP/bin:$PATH"

# ---- harness ---------------------------------------------------------------
# Returns: "MERGE" when the block falls through to the merge, "STOP" when it
# returns non-zero. Both are correct outcomes; which one is correct depends on
# the fixture.
run_case() {
  local fixture="$1"
  printf '%s\n' "$fixture" >"$TMP/fixture.jsonl"
  echo 1 >"$TMP/cursor"
  : >"$TMP/calls"
  # The block is sourced inside a function so its `local` and `return` are legal.
  # `await` must NOT end in an explicit `return` — a `return` in a sourced file
  # ends the sourcing, not the caller, so a trailing `return 0` would swallow
  # every stop decision and report MERGE for all of them.
  #
  # Its stdout goes to stderr: the block narrates progress, and that narration
  # would otherwise be indistinguishable from the verdict.
  FIXTURE_FILE="$TMP/fixture.jsonl" FIXTURE_CURSOR="$TMP/cursor" CALL_LOG="$TMP/calls" \
  bash -c '
    set -uo pipefail
    number=1 head=develop base=stage
    await() { . "'"$TMP"'/block.sh"; }
    if await >&2; then echo MERGE; else echo STOP; fi
  ' 2>"$TMP/stderr"
}

check() {  # check <name> <expected> <fixture>
  local got; got="$(run_case "$3")"
  if [[ "$got" == "$2" ]]; then
    pass "$1"
  else
    fail "$1" "expected $2, got $got"
  fi
}

SKIPPED_PLACEHOLDER='{"name":"Contract (${{ matrix.os }})","status":"COMPLETED","conclusion":"SKIPPED"}'
OK='{"name":"check-branch-flow","status":"COMPLETED","conclusion":"SUCCESS"}'
OK2='{"name":"Contract (ubuntu-latest)","status":"COMPLETED","conclusion":"SUCCESS"}'
RUNNING='{"name":"Contract (macos-latest)","status":"IN_PROGRESS","conclusion":null}'
BAD='{"name":"Contract (ubuntu-latest)","status":"COMPLETED","conclusion":"FAILURE"}'

# [1] The regression this file was written for, stated so that only correct
# behaviour passes. This is PR #115's rollup at the instant the old code merged:
# one skipped placeholder, no real jobs yet, GitHub still calling the PR BLOCKED.
#
# The fixture then turns red. A block that merges on the placeholder alone never
# sees that and reports MERGE; a block that waits sees the failure and stops. An
# "it eventually merges" fixture cannot tell the two apart — both end in MERGE —
# which is why the assertion is the negative one.
check "[1] a lone skipped matrix placeholder does not count as a finished CI run" STOP \
"$(printf '%s\n%s\n' \
  "{\"mergeStateStatus\":\"BLOCKED\",\"statusCheckRollup\":[$SKIPPED_PLACEHOLDER]}" \
  "{\"mergeStateStatus\":\"BLOCKED\",\"statusCheckRollup\":[$SKIPPED_PLACEHOLDER,$BAD]}")"

# [1b] The same opening, resolving green: the promotion must still go through.
check "[1b] once the real checks arrive and pass, it merges" MERGE \
"$(printf '%s\n%s\n' \
  "{\"mergeStateStatus\":\"BLOCKED\",\"statusCheckRollup\":[$SKIPPED_PLACEHOLDER]}" \
  "{\"mergeStateStatus\":\"CLEAN\",\"statusCheckRollup\":[$SKIPPED_PLACEHOLDER,$OK,$OK2]}")"

# [2] The same opening state that never resolves. It must give up and leave the
# PR open, not merge.
check "[2] a PR that stays BLOCKED is never merged" STOP \
  "{\"mergeStateStatus\":\"BLOCKED\",\"statusCheckRollup\":[$SKIPPED_PLACEHOLDER]}"

# [3] The trap on the other side. Requiring CLEAN alone would deadlock here:
# the skipped placeholder holds the rollup at UNSTABLE forever even though
# every required check has passed.
check "[3] UNSTABLE with nothing pending still merges" MERGE \
  "{\"mergeStateStatus\":\"UNSTABLE\",\"statusCheckRollup\":[$SKIPPED_PLACEHOLDER,$OK]}"

# [4] A real failure stops the chain immediately — it does not wait out 900s.
check "[4] a failed check stops the chain" STOP \
  "{\"mergeStateStatus\":\"BLOCKED\",\"statusCheckRollup\":[$BAD,$OK]}"

# [5] Still running: not ready, whatever the state says.
check "[5] a check still in progress is not ready" STOP \
  "{\"mergeStateStatus\":\"CLEAN\",\"statusCheckRollup\":[$RUNNING,$OK]}"

# [6] A commit status (the other rollup shape) carries `state`, not
# `status`/`conclusion`. Reading only check runs makes these invisible.
check "[6] a pending commit status is not ready" STOP \
  '{"mergeStateStatus":"CLEAN","statusCheckRollup":[{"context":"ci/legacy","state":"PENDING"}]}'
check "[7] a failed commit status stops the chain" STOP \
  '{"mergeStateStatus":"CLEAN","statusCheckRollup":[{"context":"ci/legacy","state":"FAILURE"}]}'

# [8] A repo with no CI at all must still promote.
check "[8] no checks configured merges" MERGE \
  '{"mergeStateStatus":"CLEAN","statusCheckRollup":[]}'

# [9] Conflicts and drafts are not worth 900s of waiting.
check "[9] a conflicting PR stops immediately" STOP \
  "{\"mergeStateStatus\":\"DIRTY\",\"statusCheckRollup\":[$OK]}"

# [10] UNKNOWN is GitHub not having computed mergeability yet, not a verdict.
check "[10] UNKNOWN is not treated as ready" STOP \
  "{\"mergeStateStatus\":\"UNKNOWN\",\"statusCheckRollup\":[$OK]}"

# [11] BEHIND asks for an update and then proceeds.
run_case "$(printf '%s\n%s\n' \
  "{\"mergeStateStatus\":\"BEHIND\",\"statusCheckRollup\":[$OK]}" \
  "{\"mergeStateStatus\":\"CLEAN\",\"statusCheckRollup\":[$OK]}")" >/dev/null
if grep -q update-branch "$TMP/calls"; then
  pass "[11] a BEHIND head is brought up to date rather than waited out"
else
  fail "[11] BEHIND did not trigger update-branch"
fi

echo
echo "  passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]] || exit 1
