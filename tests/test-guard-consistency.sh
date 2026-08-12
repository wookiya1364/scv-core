#!/usr/bin/env bash
# No shipped document may sanction or instruct an action the guard denies.
#
# Lives in the repo's tests/, not core/tests/, for two reasons that both matter:
#   - tools/export-core.sh ships core/ and tools/ only, so this file never enters
#     a plugin payload;
#   - tests/test-host-neutral.sh scans core/ for forbidden host tokens, and this
#     checker must carry the host-flavored phrases it searches for. Under
#     core/tests/ it would trip that scan on its own phrase list.
#
# The declaration it reads is core/contracts/guard.md.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTRACT="$ROOT/core/contracts/guard.md"
ACTIONS="$ROOT/core/actions.json"
SCAN_DIRS=("$ROOT/core/protocols" "$ROOT/core/template" "$ROOT/core/integrations")

PASS=0; FAIL=0
pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; [[ $# -gt 1 ]] && printf '%s\n' "$2" | sed 's/^/      /'; FAIL=$((FAIL+1)); }

[[ -f "$CONTRACT" ]] || { echo "missing $CONTRACT" >&2; exit 1; }

block() { sed -n "/\`\`\`guard:$1/,/\`\`\`\$/p" "$CONTRACT" | grep -vE '^```'; }

# ---- [1] the declared mint set equals the shipped action list --------------
# The Rule B design rests entirely on "every action mints". Adding a sixteenth
# action must fail here until someone records a guard decision for it.
declared="$(block mint | tr -d ' ' | grep -v '^$' | sort)"
if command -v python3 >/dev/null 2>&1; then
  actual="$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
a=d["actions"] if isinstance(d,dict) and "actions" in d else d
ids=list(a.keys()) if isinstance(a,dict) else [x["id"] for x in a]
print("\n".join(sorted(ids)))' "$ACTIONS" 2>/dev/null)"
  if [[ -z "$actual" ]]; then
    fail "[1] could not read action ids from core/actions.json"
  elif [[ "$declared" == "$actual" ]]; then
    pass "[1] the mint set matches core/actions.json ($(wc -l <<<"$actual" | tr -d ' ') actions)"
  else
    fail "[1] the mint set and core/actions.json disagree" "$(diff <(echo "$declared") <(echo "$actual") | head -12)"
  fi
else
  pass "[1] (skip) python3 unavailable"
fi

# ---- [2] no shipped document sanctions a guard-denied action ---------------
# English and Korean both, because raw/README.md, loop-runner.md, routines/ and
# every routine example are Korean-only — an English-only sweep sees none of them.
#
# There is deliberately NO token allowlist. An earlier design exempted a hit when
# an action name appeared nearby, which would have excused
# "via action:promote or by hand" — and "do it via <command> or by hand" is the
# canonical shape of the contradiction. The action token correlates with the
# violation, not against it. Exceptions are explicit file:line anchors instead.
PHRASES='by hand|hand-write|hand-author|write .{0,20}yourself|수동 작성|손으로 (쓰|작성|만들)|직접 작성'

# Anchors: "<path>:<line> — reason"
mapfile -t ANCHORS < <(block exceptions | grep -E '^[^ ].*:[0-9]+' || true)
anchor_matches() {  # anchor_matches <relpath> <line>
  local rel="$1" line="$2" a
  for a in "${ANCHORS[@]}"; do
    [[ "${a%% —*}" == "$rel:$line" ]] && return 0
  done
  return 1
}

scanned=0; matched=0; violations=""
for dir in "${SCAN_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r file; do
    scanned=$((scanned+1))
    while IFS=: read -r lineno text; do
      [[ -n "$lineno" ]] || continue
      matched=$((matched+1))
      rel="${file#$ROOT/}"
      # Every hit needs an explicit anchor. There is deliberately no automatic
      # "this sentence forbids it" heuristic: a negation-word test on the line
      # passed "Don't create now. You can create it later via action:promote or
      # by hand." — the negation belonged to a different clause than the bypass.
      # The phrase set matches a handful of lines across the whole payload, so
      # naming each one costs little and cannot misfire.
      anchor_matches "$rel" "$lineno" && continue
      violations="$violations$rel:$lineno: ${text:0:110}"$'\n'
    done < <(grep -nEi "$PHRASES" "$file" || true)
  done < <(find "$dir" -type f -name '*.md')
done

if [[ -z "$violations" ]]; then
  pass "[2] no shipped document sanctions a guard-denied action"
else
  fail "[2] shipped documents sanction guard-denied actions" "$violations"
fi

# ---- [3] every anchor still matches its recorded line ----------------------
stale=""
for a in "${ANCHORS[@]}"; do
  loc="${a%% —*}"; rel="${loc%%:*}"; line="${loc##*:}"
  [[ -f "$ROOT/$rel" ]] || { stale="$stale$loc (file gone)"$'\n'; continue; }
  text="$(sed -n "${line}p" "$ROOT/$rel")"
  printf '%s' "$text" | grep -qEi "$PHRASES" \
    || stale="$stale$loc (the excused phrase is no longer there)"$'\n'
done
if [[ -z "$stale" ]]; then
  pass "[3] every sanctioned-exception anchor still matches"
else
  fail "[3] stale exception anchors — an excuse outlived its text" "$stale"
fi

# ---- [4] the scan actually scanned something ------------------------------
# Without this a broken glob turns the whole checker into a silent no-op that
# reports success forever.
if (( scanned > 20 && matched > 0 )); then
  pass "[4] the sweep is live ($scanned files, $matched phrase hits)"
else
  fail "[4] the sweep did not run (scanned=$scanned matched=$matched)"
fi

echo
echo "  passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]] || exit 1
