#!/usr/bin/env bash
# test-timing-budget.sh — 부하에 맞춰 늘어나는 시간 예산 (v0.52.0+).
#
# 고치려는 병: 고정된 밀리초 예산은 기계가 바쁘면 코드와 무관하게 무너진다. 그 관문 하나를
# 계획 25건이 공유해서, 부하 한 번에 25건이 함께 붉었다.
# 고친 방식: source 할 때 이 셸이 얼마나 굼뜬지 한 번 재서 예산에 곱한다.
#
# 여기서 보는 것 넷: 한가하면 예산이 그대로일 것 · 바쁘면 늘어날 것 ·
# 아무리 바빠도 무한정 늘어나지는 않을 것 · 같은 실행 안에서 답이 흔들리지 않을 것.
set -uo pipefail

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB="$HERE/lib/timing.sh"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; fail=$((fail+1)); }
want(){ [[ "$2" == "$3" ]] && ok "$1" || bad "$1 — 기대 $3 / 실제 $2"; }

[[ -f "$LIB" ]] || { echo "  ✗ 라이브러리가 없다: $LIB"; exit 1; }
bash -n "$LIB" || { echo "  ✗ 문법 오류"; exit 1; }

echo ""
echo "── [T1] 배수를 강제하면 그대로 쓴다 ──"
want "배수 1 → 예산 그대로" \
  "$(SCV_TEST_TIME_SCALE=1 bash -c "source '$LIB'; scv_budget_ms 2000")" "2000"
want "배수 3 → 세 배" \
  "$(SCV_TEST_TIME_SCALE=3 bash -c "source '$LIB'; scv_budget_ms 2000")" "6000"
want "배수는 변수로도 보인다" \
  "$(SCV_TEST_TIME_SCALE=5 bash -c "source '$LIB'; printf %s \"\$SCV_TIME_SCALE\"")" "5"

echo ""
echo "── [T2] 같은 실행 안에서 답이 흔들리지 않는다 ──"
# 고치려던 병이 바로 이것이다: 물을 때마다 다시 재면 한 검사 안에서도 기준이 달라진다.
v="$(bash -c "source '$LIB'; a=\$(scv_budget_ms 2000); b=\$(scv_budget_ms 2000); c=\$(scv_budget_ms 2000); echo \"\$a \$b \$c\"")"
read -r a b c <<<"$v"
[[ "$a" == "$b" && "$b" == "$c" ]] && ok "세 번 물어도 같다 ($a)" || bad "흔들린다: $a $b $c"

echo ""
echo "── [T3] 기준보다 빠르면 예산이 그대로다 ──"
# 진짜 한가한 기계를 기다리지 않는다. 기준을 넉넉히 줘서 "보정이 기준보다 빠른 경우" 를
# 결정적으로 만든다 — 이 검사가 기계 사정에 좌우되면, 고치려던 병을 검사에 옮겨 심는 것이다.
s="$(bash -c "SCV_TIME_REF_MS=600000 source '$LIB'; printf %s \"\$SCV_TIME_SCALE\"")"
want "기준보다 빠르면 배수 1" "$s" "1"
want "그때 예산은 그대로" \
  "$(bash -c "SCV_TIME_REF_MS=600000 source '$LIB'; scv_budget_ms 2000")" "2000"

echo ""
echo "── [T4] 바쁘면 예산이 늘어난다 ──"
# 보정 자체를 느리게 만들어 부하를 흉내 낸다. 진짜 부하를 걸면 검사가 기계 사정에
# 좌우되어, 고치려던 병을 검사 쪽에 그대로 옮겨 심게 된다.
busy="$(bash -c "SCV_TIME_REF_MS=1 source '$LIB'; printf %s \"\$SCV_TIME_SCALE\"")"
(( busy > 1 )) && ok "굼뜬 셸에서 배수가 1보다 크다 ($busy)" || bad "굼떠도 배수가 그대로다 ($busy)"
bud="$(bash -c "SCV_TIME_REF_MS=1 source '$LIB'; scv_budget_ms 2000")"
(( bud > 2000 )) && ok "예산도 함께 늘었다 (${bud}ms)" || bad "예산이 안 늘었다 (${bud}ms)"

echo ""
echo "── [T5] 아무리 바빠도 상한을 넘지 않는다 ──"
# 상한이 없으면 아주 바쁜 기계에서 어떤 느림도 통과해 버려, 검사가 의미를 잃는다.
cap="$(bash -c "SCV_TIME_REF_MS=1 SCV_TIME_SCALE_MAX=3 source '$LIB'; printf %s \"\$SCV_TIME_SCALE\"")"
(( cap <= 3 )) && ok "상한 3을 지킨다 ($cap)" || bad "상한을 넘었다 ($cap)"
cap2="$(bash -c "SCV_TEST_TIME_SCALE=99 SCV_TIME_SCALE_MAX=3 source '$LIB'; printf %s \"\$SCV_TIME_SCALE\"")"
want "강제 배수는 상한보다 우선한다 (CI 재현용)" "$cap2" "99"

echo ""
echo "── [T6] 이상한 입력에 무너지지 않는다 ──"
want "숫자가 아닌 예산 → 0" "$(SCV_TEST_TIME_SCALE=2 bash -c "source '$LIB'; scv_budget_ms abc")" "0"
want "예산 없음 → 0" "$(SCV_TEST_TIME_SCALE=2 bash -c "source '$LIB'; scv_budget_ms")" "0"
want "숫자가 아닌 강제 배수는 무시하고 스스로 잰다" \
  "$(SCV_TEST_TIME_SCALE=abc bash -c "SCV_TIME_REF_MS=600000 source '$LIB'; printf %s \"\$SCV_TIME_SCALE\"")" "1"

echo ""
echo "── [T7] 시각 함수가 밀리초를 준다 ──"
n="$(bash -c "source '$LIB'; scv_now_ms")"
[[ "$n" =~ ^[0-9]{13,}$ ]] && ok "13자리 이상 (밀리초)" || bad "밀리초가 아니다: $n"

echo ""
echo "── [T8] 예산을 쓰는 검사들이 라이브러리를 부른다 ──"
for f in test-graph test-answer-lint-source test-graft-adapter; do
  grep -q 'lib/timing.sh' "$HERE/$f.sh" && ok "$f 가 라이브러리를 부른다" || bad "$f 가 라이브러리를 안 부른다"
done
# 고정 밀리초가 다시 기어들지 않게 막는다.
if grep -nE '\(\( *t1 *- *t0 *<= *[0-9]+ *\)\)' "$HERE"/test-*.sh | grep -v scv_budget_ms; then
  bad "고정 밀리초 예산이 남아 있다 (위 줄)"
else
  ok "고정 밀리초 예산이 남아 있지 않다"
fi

echo ""
echo "── test-timing-budget: $pass passed, $fail failed ──"
[[ $fail -eq 0 ]]
