#!/usr/bin/env bash
# test-composition-principles.sh — 합성 설계 원칙이 SCV 계약과 계획 절차에 들어갔는지, 체크리스트가 빠지면
# 기획서 검사가 경고하는지 본다 (계획 20261111-wookiya1364-composition-principles · TESTS.md T1 ~ T11).
#
# Run: bash core/tests/test-composition-principles.sh
set -uo pipefail

CORE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
DOC="$CORE/contracts/composition.md"
PUR="$CORE/contracts/purity.md"
PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✖ FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "T1. 계약 문서 — 합성 원칙의 낱말"
c=0; for k in '요소 단위' '순회는 한' '중간 모음' '지연 평가' '구조 공유' '단항'; do grep -q -- "$k" "$DOC" 2>/dev/null && c=$((c + 1)) || echo "      없음: $k"; done
[[ $c == 6 ]] && ok "OK [T1] 6/6" || fail "[T1] $c/6"

echo "T2. 계약 문서 — 언어별 수단 표 (언어 9개 + 셸, 칸 5개)"
rows="$(awk '/^## 언어별 수단/{f=1; next} /^## /{f=0} f && /^\| / && !/^\| 언어 /' "$DOC" 2>/dev/null)"
n="$(grep -c . <<<"$rows")"; cols=1
while IFS= read -r r; do [[ -n "$r" ]] || continue; k="$(awk -F'|' '{print NF-2}' <<<"$r")"; [[ "$k" == 5 ]] || cols=0; done <<<"$rows"
miss=""; for l in 'TypeScript/JS' Python Java Kotlin 'C#' Go Rust Scala Haskell 셸; do grep -q "^| $l |" <<<"$rows" || miss="$miss $l"; done
[[ "$n" == 10 && $cols == 1 && -z "$miss" ]] && ok "OK [T2] 10 rows × 5 cells" || fail "[T2] rows=$n cols-ok=$cols missing:$miss"
# 문서 표에는 줄글을 넣지 않는다 — 칸은 60바이트(한글 스무 자)까지. awk 마다 글자 · 바이트 세는 법이 달라 넉넉한 쪽으로 잡는다
long="$(awk -F'|' '{ for (i = 2; i < NF; i++) { c = $i; gsub(/^ +| +$/, "", c); if (length(c) > 60) print c } }' <<<"$rows")"
[[ -z "$long" ]] && ok "OK [T2b] no prose cells" || fail "[T2b] long cell: $(head -1 <<<"$long")"

echo "T3. 계약 문서 — 막는 것과 못 막는 것"
sec="$(awk '/^## SCV 가 막는 것과 못 막는 것/{f=1; next} /^## /{f=0} f' "$DOC" 2>/dev/null)"
grep -q '최대 성능은 증명할 수 없다' <<<"$sec" && ! grep -q '최대 성능을 보장' "$DOC" && ok "OK [T3] says it cannot be proven; never promises it" || fail "[T3]"

echo "T4. 계약 문서 — 체크리스트 10개"
n="$(awk '/^## 체크리스트/{f=1; next} /^## /{f=0} f && /^[0-9]+\. /' "$DOC" 2>/dev/null | grep -c .)"
[[ "$n" == 10 ]] && ok "OK [T4] 10 questions" || fail "[T4] $n"

echo "T5. 기존 순수성 문서가 새 문서를 가리킨다"
[[ "$(grep -c 'composition.md' "$PUR")" == 1 ]] && ok "OK [T5] one pointer" || fail "[T5] $(grep -c 'composition.md' "$PUR")"

echo
echo "── $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
