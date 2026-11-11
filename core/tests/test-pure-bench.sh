#!/usr/bin/env bash
# test-pure-bench.sh — 재는 명령(계획 20261111-wookiya1364-pure-bench-and-gate)의 시험.
# 순수 함수는 값으로, 실행기는 임시 폴더의 작은 함수로 본다.
#
# Run: bash core/tests/test-pure-bench.sh
set -uo pipefail

CORE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
PB="$CORE/scripts/pure-bench.sh"
# shellcheck source=../scripts/lib/pure-catalog.sh
source "$CORE/scripts/lib/pure-catalog.sh"
# shellcheck source=../scripts/lib/pure-bench.sh
source "$CORE/scripts/lib/pure-bench.sh"
PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✖ FAIL: $1"; FAIL=$((FAIL + 1)); }
eq()   { if [[ "$2" == "$3" ]]; then ok "OK [$1]"; else fail "[$1] want [$2] got [$3]"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "S1. 인자 늘리기 — 줄 · 낱말 · 늘릴 수 없음"
eq "S1 lines"            "\$'a\\nb\\na\\nb' \"x y\""  "$(pb_scale_args "\$'a\\nb' \"x y\"" 2)"
eq "S1 words"            '"x y x y" k'                 "$(pb_scale_args '"x y" k' 2)"
eq "S1 here-string"      "<<< \$'p\\nq\\np\\nq\\np\\nq'" "$(pb_scale_args "<<< \$'p\\nq'" 3)"
eq "S1 trailing newline" "\$'a\\nb\\na\\nb\\n'"        "$(pb_scale_args "\$'a\\nb\\n'" 2)"
pb_scale_args '"1.2.3" k' 2 >"$TMP/o"; st=$?
eq "S1 unscalable keeps the text" '"1.2.3" k' "$(cat "$TMP/o")"; eq "S1 unscalable returns 1" 1 "$st"
eq "S1 a quote inside a value" "\"it\\\"s ok it\\\"s ok\"" "$(pb_scale_args "\"it\\\"s ok\"" 2)"
# 늘린 글은 셸이 다시 읽을 수 있어야 한다 — 줄 수가 정확히 N배
eval "set -- $(pb_scale_args "\$'a\\tb\\nc'" 25)"; eq "S1 25 times = 50 lines" 50 "$(printf '%s\n' "$1" | grep -c .)"

echo "S2. 잴 목록 — 사전 글에서"
CAT=$'# 세기\n\n### f_lines\n- 역할: 센다\n- 위치: scripts/lib/a.sh · @pure · sh\n- 예: `$\'a\\nb\' → "2"`\n- 예: `"" → "0"`\n\n### f_fixed\n- 역할: 견준다\n- 위치: scripts/lib/b.sh · @deterministic · sh\n- 예: `1.2.3 1.2.4 → ""`\n\n### f_noexample\n- 역할: 없다\n- 위치: scripts/lib/c.sh · @pure · sh\n\n### g_ts\n- 역할: 다른 언어\n- 위치: src/x.ts · @pure · ts\n- 예: `"a b" → "2"`'
T="$(pb_targets "$CAT" "")"
eq "S2 three functions with an example" 3 "$(grep -c . <<<"$T")"
IFS=$'\t' read -r n f l a1 a4 sc <<<"$(sed -n 1p <<<"$T")"
eq "S2 name · file · lang" "f_lines scripts/lib/a.sh sh" "$n $f $l"
eval "set -- $a1"; c1="$(printf '%s\n' "$1" | grep -c .)"; eval "set -- $a4"; c4="$(printf '%s\n' "$1" | grep -c .)"
eq "S2 1x = 50 lines, 4x = 200 lines, scalable" "50 200 1" "$c1 $c4 $sc"
eq "S2 only the first example is used" 1 "$(grep -c '^f_lines' <<<"$T")"
eq "S2 a fixed-size example is marked 0" "f_fixed 0" "$(awk -F'\t' '$1 == "f_fixed" { print $1, $6 }' <<<"$T")"
eq "S2 other languages keep their lang" "ts" "$(awk -F'\t' '$1 == "g_ts" { print $3 }' <<<"$T")"
eq "S2 --only filter" "f_fixed" "$(pb_targets "$CAT" $'f_fixed\nnope' | cut -f1)"

echo "S3. 명령 — 이 저장소의 사전으로"
if [[ -d "$CORE/../scv/core/catalog/pure" ]]; then
  bash "$PB" targets > "$TMP/all.tsv"; st=$?
  want="$(grep -h -A8 '^### ' "$CORE"/../scv/core/catalog/pure/[a-z]*.md | grep -c '^### ')"
  have="$(grep -c . "$TMP/all.tsv")"
  [[ $st == 0 && "$have" -gt 100 && "$have" -le "$want" ]] && ok "OK [S3] $have of $want functions listed" || fail "[S3] st=$st have=$have want=$want"
  eq "S3 six columns on every line" 0 "$(awk -F'\t' 'NF != 6' "$TMP/all.tsv" | grep -c .)"
  eq "S3 --only" "scv_tc_words" "$(bash "$PB" targets --only scv_tc_words | cut -f1)"
else
  echo "  - SKIP [S3] 이 저장소에 사전이 없음"
fi
bash "$PB" targets --catalog "$TMP/none" >/dev/null 2>&1; eq "S3 missing catalog → usage error" 2 "$?"

echo
echo "── $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
