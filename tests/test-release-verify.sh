#!/usr/bin/env bash
# test-release-verify.sh — 릴리스 검증이 여섯 조각으로 나뉘어도 모든 시험이 한 번씩 돌고,
# 조각이 모두 통과해야만 릴리스가 나가는지 본다 (계획 20261112-wookiya1364-release-verify-shards).
# 설정 파일의 모양은 글로 읽고, 조각 나누기는 조각 실행기의 순수 함수를 그대로 불러 본다.
#
# Run: bash tests/test-release-verify.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REL="$ROOT/.github/workflows/release.yml"
CI="$ROOT/.github/workflows/core-ci.yml"
RUNNER="$ROOT/core/tests/run-focused.sh"
PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✖ FAIL: $1"; FAIL=$((FAIL + 1)); }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# 작업 하나의 글 — '  <이름>:' 줄부터 다음 작업 줄 앞까지
job_block() { awk -v j="$2" '
  $0 ~ "^  " j ":[[:space:]]*$" { on = 1; print; next }
  on && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ { exit }
  on { print }' "$1"; }

# 조각 명령에서 '--shard' 앞의 인자만(무엇을 도는가)
shard_args() { grep -E 'run-focused\.sh .*--shard' <<< "$1" | head -1 | sed -E 's/^.*run-focused\.sh[[:space:]]+//; s/[[:space:]]*--shard.*$//'; }

# 릴리스 설정의 문제를 한 줄에 하나씩 낸다(없으면 빈 글). 인자: 릴리스 설정 · PR 검사 설정
rv_problems() {
  local rel="$1" ci="$2" v r list n cmd_n want got
  v="$(job_block "$rel" verify)"; r="$(job_block "$rel" release)"
  [[ -n "$v" ]] || { echo "조각 작업(verify)이 없다"; return 0; }
  list="$(grep -E '^[[:space:]]+shard:[[:space:]]*\[' <<< "$v" | head -1 | sed -E 's/^[^[]*\[//; s/\].*$//; s/[[:space:]]//g')"
  n="$(tr ',' '\n' <<< "$list" | grep -c .)"
  [[ "$list" == "$(seq -s, 1 "$n" | sed 's/,$//')" ]] || echo "조각 목록이 1부터 차례가 아니다: [$list]"
  cmd_n="$(grep -E 'run-focused\.sh .*--shard' <<< "$v" | head -1 | sed -E 's/^.*--shard[[:space:]]+[^/]*\/([0-9]+).*$/\1/')"
  [[ "$cmd_n" == "$n" ]] || echo "조각 수가 어긋난다: 목록 ${n}개 · 명령 /${cmd_n:-없음}"
  want="$(shard_args "$(job_block "$ci" shards-ubuntu)")"; got="$(shard_args "$v")"
  [[ -n "$got" && "$got" == "$want" ]] || echo "조각이 도는 것이 PR 검사와 다르다: [$got] ≠ [$want]"
  grep -Eq '^[[:space:]]+needs:[[:space:]]*(verify|\[[[:space:]]*verify[[:space:]]*\])[[:space:]]*$' <<< "$r" || echo "릴리스 작업이 조각을 기다리지 않는다(needs: verify 없음)"
  grep -Eq "^[[:space:]]+if:.*github\.event_name == 'push'" <<< "$r" || echo "릴리스 작업이 꼬리표를 올릴 때만 돌지 않는다"
  grep -Eq 'for[[:space:]]+[A-Za-z_]+[[:space:]]+in[[:space:]]+core/tests/test-\*\.sh|bash tests/run\.sh' "$rel" && echo "시험을 하나씩 도는 반복이 다시 생겼다"
  grep -q 'pnpm/action-setup' <<< "$v" && grep -q 'actions/setup-node' <<< "$v" || echo "조각에 기획서 도구(pnpm · node)가 없다 — 기획서 시험이 건너뛴다"
  grep -Eq '^[[:space:]]+cache:' <<< "$v" && echo "조각의 node 준비에 cache 가 있다 — 설치가 없는 조각이 끝에서 실패한다"
  return 0
}

echo "T4. 릴리스 설정 — 여섯 조각, 릴리스는 조각을 기다린다"
p="$(rv_problems "$REL" "$CI")"
[[ -z "$p" ]] && ok "릴리스 설정에 문제 없음" || fail "릴리스 설정: $(tr '\n' ';' <<< "$p")"
n_rel="$(job_block "$REL" verify | grep -E 'run-focused\.sh .*--shard' | head -1 | sed -E 's/^.*--shard[[:space:]]+[^/]*\/([0-9]+).*$/\1/')"
[[ "$n_rel" == 6 ]] && ok "조각은 여섯" || fail "조각 수: ${n_rel:-없음}"

echo "T4b. 틀어진 설정은 잡는다"
mut() {  # <이름> <sed 식> <나와야 할 글>
  sed -E "$2" "$REL" > "$TMP/$1.yml"
  if cmp -s "$REL" "$TMP/$1.yml"; then fail "$1 — 바꿔 본 것이 원본과 같다(시험이 낡았다)"; return; fi
  if rv_problems "$TMP/$1.yml" "$CI" | grep -q "$3"; then ok "$1 → 잡음"; else fail "$1 → 못 잡음: [$(rv_problems "$TMP/$1.yml" "$CI" | tr '\n' ';')]"; fi
}
mut "조각 목록을 다섯으로"     's/shard: \[1, 2, 3, 4, 5, 6\]/shard: [1, 2, 3, 4, 5]/'  "조각 수가 어긋난다"
mut "기다림을 지움"            '/^    needs: verify$/d'                               "조각을 기다리지 않는다"
mut "PR 에서도 릴리스가 돎"    "/^    if: github.event_name == 'push'\$/d"             "꼬리표를 올릴 때만"
mut "도는 폴더를 줄임"         's/--dir tests --dir core\/tests --also/--dir core\/tests --also/' "PR 검사와 다르다"
mut "기획서 도구를 뺌"         '/pnpm\/action-setup@v4/d'                              "기획서 도구"
{ cat "$REL"; printf '          for test_file in core/tests/test-*.sh; do bash "$test_file"; done\n'; } > "$TMP/loop.yml"
rv_problems "$TMP/loop.yml" "$CI" | grep -q "반복이 다시 생겼다" && ok "하나씩 도는 반복을 다시 넣음 → 잡음" || fail "반복을 못 잡음"

echo "T4c · T3. 여섯 조각이 모든 시험을 한 번씩 돈다 — 시간표에 빠진 시험이 없고 조각이 고르다"
# shellcheck source=../core/tests/run-focused.sh
source "$RUNNER"
set +e   # 실행기가 켠 옵션과 무관하게 아래 판정을 끝까지 돈다
ALL="$(cd "$ROOT" && rf_list_tests D:tests D:core/tests F:core/tests/run-dry.sh | rf_classify)"
n_all="$(grep -c . <<< "$ALL")"
keys_of() { cut -f2 <<< "$1" | while IFS= read -r q; do [[ -n "$q" ]] && rf_key "$q"; done; }
check_table() {  # <이름> <시간표 파일> <조각 수>
  local name="$1" file="$2" n="$3" t i part union="" missing sums max min avg longest total
  t="$(cat "$file")"
  missing="$(keys_of "$ALL" | while IFS= read -r k; do awk -F'\t' -v k="$k" '$1 == k { f = 1 } END { exit !f }' <<< "$t" || printf '%s ' "$k"; done)"
  [[ -z "$missing" ]] && ok "$name 시간표: 모으는 시험 ${n_all}개가 모두 있다" || fail "$name 시간표에 없는 시험: $missing"
  sums=""
  for i in $(seq 1 "$n"); do
    part="$(rf_partition "$t" "$i" "$n" <<< "$ALL")"
    union+="$part"$'\n'
    sums+="$(keys_of "$part" | while IFS= read -r k; do awk -F'\t' -v k="$k" '$1 == k { print $2; f = 1 } END { if (!f) print 5 }' <<< "$t"; done | awk '{ s += $1 } END { print s + 0 }') "
  done
  [[ "$(grep . <<< "$union" | LC_ALL=C sort)" == "$(LC_ALL=C sort <<< "$ALL")" ]] \
    && ok "$name: ${n}조각의 합집합 = 전체 ${n_all}개 — 빠짐 0 · 겹침 0" || fail "$name: 조각의 합집합이 전체와 다르다"
  total="$(grep -v '^#' <<< "$t" | awk -F'\t' '{ s += $2 } END { print s + 0 }')"
  longest="$(grep -v '^#' <<< "$t" | awk -F'\t' '$2 > m { m = $2 } END { print m + 0 }')"
  max="$(tr ' ' '\n' <<< "$sums" | awk '$1 > m { m = $1 } END { print m + 0 }')"; avg=$(( total / n ))
  (( max <= avg + longest )) && ok "$name: 조각 합 [${sums% }]초 — 가장 무거운 ${max}초 ≤ 평균 ${avg} + 가장 긴 시험 ${longest}" \
    || fail "$name: 조각이 쏠렸다 [${sums% }] (평균 $avg · 가장 긴 시험 $longest)"
  # 시험 하나가 조각 하나만큼 길어지면 그 조각을 고르게 맞출 수 없다 — 평균의 3분의 2 를 넘기 전에 나눠야 한다.
  # (처음에는 절반으로 잡았으나, 나눈 재는 명령 시험의 가장 긴 파일이 리눅스에서 127초 · 평균 211초였다.)
  (( longest * 3 <= avg * 2 )) && ok "$name: 가장 긴 시험 ${longest}초 ≤ 조각 평균 ${avg}초의 3분의 2" \
    || fail "$name: 가장 긴 시험 ${longest}초가 조각 평균 ${avg}초의 3분의 2 를 넘는다 — 그 시험을 나눠라"
  min="$(tr ' ' '\n' <<< "$sums" | grep . | awk 'NR == 1 || $1 < m { m = $1 } END { print m + 0 }')"
  (( max - min <= 5 )) && ok "$name: 가장 무거운 조각 − 가장 가벼운 조각 = $(( max - min ))초 (5초 안)" \
    || fail "$name: 조각의 차이 $(( max - min ))초 — 시간표를 다시 적어라"
}
check_table "리눅스" "$ROOT/core/tests/timings.tsv" 6
check_table "맥"     "$ROOT/core/tests/timings-macos.tsv" 5
# 시간표에서 한 줄을 지우면 그 이름을 댄다
grep -v '^core/tests/test-run-focused\.sh' "$ROOT/core/tests/timings.tsv" > "$TMP/short.tsv"
t="$(cat "$TMP/short.tsv")"
miss="$(keys_of "$ALL" | while IFS= read -r k; do awk -F'\t' -v k="$k" '$1 == k { f = 1 } END { exit !f }' <<< "$t" || printf '%s ' "$k"; done)"
[[ "$miss" == "core/tests/test-run-focused.sh " ]] && ok "시간표에서 한 줄을 지우면 그 이름을 댄다" || fail "지운 줄을 못 댐: [$miss]"

echo "test-release-verify: PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
