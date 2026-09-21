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

# Anchors: '<path>:"<phrase>" — reason' (0.57.0). A phrase unique to the excused
# line, not a line number: shortening a protocol above the excused line used to
# orphan the excuse (0.56.0 shipped one such stale anchor). [3] fails when the
# phrase vanishes, matches more than one line, or its line no longer trips PHRASES.
mapfile -t ANCHORS < <(block exceptions | grep -E '^[^ ]+:"' || true)
anchor_file()   { local a="$1"; printf '%s' "${a%%:\"*}"; }
anchor_phrase() { local a="$1"; a="${a#*:\"}"; printf '%s' "${a%%\" —*}"; }
anchor_matches() {  # anchor_matches <relpath> <line text>
  local rel="$1" text="$2" a
  for a in "${ANCHORS[@]}"; do
    [[ "$(anchor_file "$a")" == "$rel" && "$text" == *"$(anchor_phrase "$a")"* ]] && return 0
  done
  return 1
}

# sweep <root> → one violation per line on stdout; SCANNED / MATCHED as globals.
sweep() {
  local root="$1" dir file lineno text rel
  SCANNED=0; MATCHED=0
  for dir in core/protocols core/template core/integrations; do
    [[ -d "$root/$dir" ]] || continue
    while IFS= read -r file; do
      SCANNED=$((SCANNED+1))
      while IFS=: read -r lineno text; do
        [[ -n "$lineno" ]] || continue
        MATCHED=$((MATCHED+1))
        rel="${file#$root/}"
        # Every hit needs an explicit anchor. There is deliberately no automatic
        # "this sentence forbids it" heuristic: a negation-word test on the line
        # passed "Don't create now. You can create it later via action:promote or
        # by hand." — the negation belonged to a different clause than the bypass.
        anchor_matches "$rel" "$text" && continue
        printf '%s:%s: %s\n' "$rel" "$lineno" "${text:0:110}"
      done < <(grep -nEi "$PHRASES" "$file" || true)
    done < <(find "$root/$dir" -type f -name '*.md')
  done
}

# stale_anchors <root> → one stale anchor per line on stdout.
stale_anchors() {
  local root="$1" a rel phrase loc n
  for a in "${ANCHORS[@]}"; do
    rel="$(anchor_file "$a")"; phrase="$(anchor_phrase "$a")"; loc="$rel:\"$phrase\""
    [[ -f "$root/$rel" ]] || { printf '%s (file gone)\n' "$loc"; continue; }
    n="$(grep -cF -- "$phrase" "$root/$rel" || true)"
    case "$n" in
      0) printf '%s (the excused phrase is no longer there)\n' "$loc" ;;
      1) grep -F -- "$phrase" "$root/$rel" | grep -qEi "$PHRASES" \
           || printf '%s (the line no longer needs an exception)\n' "$loc" ;;
      *) printf '%s (ambiguous — the phrase matches %s lines)\n' "$loc" "$n" ;;
    esac
  done
}

SWEEP_OUT="$(mktemp)"; sweep "$ROOT" > "$SWEEP_OUT"   # not a $(…) capture: the counters must land in this shell
violations="$(cat "$SWEEP_OUT")"; rm -f "$SWEEP_OUT"; scanned=$SCANNED; matched=$MATCHED
if [[ -z "$violations" ]]; then
  pass "[2] no shipped document sanctions a guard-denied action"
else
  fail "[2] shipped documents sanction guard-denied actions" "$violations"
fi

# ---- [3] every anchor still matches exactly one excusable line ------------
stale="$(stale_anchors "$ROOT")"
if [[ -z "$stale" ]]; then
  pass "[3] every sanctioned-exception anchor still matches"
else
  fail "[3] stale exception anchors — an excuse outlived its text" "$stale"
fi

# ---- [3b] the anchor check is alive (0.57.0) --------------------------------
# A checker that only ever passes is worth less than none: on a scratch copy,
# shift lines (must stay green), erase the phrase (must go red), duplicate it
# (must go red as ambiguous).
if (( ${#ANCHORS[@]} > 0 )); then
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  for d in core/protocols core/template core/integrations; do
    mkdir -p "$TMP/$(dirname "$d")"; cp -R "$ROOT/$d" "$TMP/$d"
  done
  frel="$(anchor_file "${ANCHORS[0]}")"; fphrase="$(anchor_phrase "${ANCHORS[0]}")"
  { printf '\n\n\n'; cat "$ROOT/$frel"; } > "$TMP/$frel"
  if [[ -z "$(sweep "$TMP")" && -z "$(stale_anchors "$TMP")" ]]; then
    pass "[3b] shifting lines does not orphan an anchor"
  else
    fail "[3b] a line shift broke an anchor" "$(stale_anchors "$TMP")"
  fi
  grep -vF -- "$fphrase" "$ROOT/$frel" > "$TMP/$frel"
  stale_anchors "$TMP" | grep -q 'no longer there' \
    && pass "[3b] a vanished phrase is reported" || fail "[3b] a vanished phrase went unnoticed"
  { cat "$ROOT/$frel"; grep -F -- "$fphrase" "$ROOT/$frel"; } > "$TMP/$frel"
  stale_anchors "$TMP" | grep -q 'ambiguous' \
    && pass "[3b] a duplicated phrase is reported as ambiguous" || fail "[3b] a duplicated phrase went unnoticed"
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
