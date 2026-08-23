#!/usr/bin/env bash
# test-settings.sh — 설정 읽기 이음매 검사 (1단계).
#
# 계획 20260823-wookiya1364-settings-json 의 TESTS.md 중 1단계 몫:
#   T1. 순수 조회 — 고정 입력, 고정 출력
#   T2. 순수부에 부수효과 없음 (정적 검사)
#   T3. 우선순위 해석 — 16가지 전수
#   T8. 없거나 깨져도 죽지 않는다
#
# 판정은 전부 문자열 비교다. "잘 된 것 같다" 는 자리가 없다.
#
# Run: bash core/tests/test-settings.sh

set -uo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
LIB="$REPO_ROOT/scripts/lib/settings.sh"

PASS=0; FAIL=0
fail() { echo "  ✖ FAIL: $1"; FAIL=$((FAIL + 1)); }
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
eq()   { if [[ "$2" == "$3" ]]; then ok "$1"; else fail "$1 — expected [$2], got [$3]"; fi; }

[[ -f "$LIB" ]] || { echo "✖ 라이브러리 없음: $LIB"; exit 1; }
# shellcheck source=../scripts/lib/settings.sh
source "$LIB"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ============================================================ T3. 우선순위 전수
echo "T3. 우선순위 — 16가지 조합 전수"

# 후보 넷의 있음/없음 = 2^4 = 16. 표본이 아니라 전체를 본다.
# 기대: 환경변수 → 비밀 → 일반 → 기본값 순으로 첫 번째 있는 값.
T3_OK=0; T3_N=0
for e in "" "E"; do
 for s in "" "S"; do
  for p in "" "P"; do
   for d in "" "D"; do
     T3_N=$((T3_N + 1))
     want=""
     if   [[ -n "$e" ]]; then want="$e"
     elif [[ -n "$s" ]]; then want="$s"
     elif [[ -n "$p" ]]; then want="$p"
     else                     want="$d"
     fi
     got="$(settings_resolve "$e" "$s" "$p" "$d")"
     if [[ "$got" == "$want" ]]; then
       T3_OK=$((T3_OK + 1))
     else
       fail "T3 [e=$e s=$s p=$p d=$d] — expected [$want], got [$got]"
     fi
   done
  done
 done
done
if [[ $T3_OK -eq $T3_N ]]; then
  ok "16가지 조합 전부 기대와 일치"
  echo "OK [T3] $T3_OK/$T3_N"
else
  echo "✖ [T3] $T3_OK/$T3_N"
fi

# 같은 입력 100회 → 같은 출력. 반복 가능성 자체를 검사한다.
R1="$(settings_resolve "" "S" "P" "D")"
SAME=1
for _ in $(seq 1 100); do
  [[ "$(settings_resolve "" "S" "P" "D")" == "$R1" ]] || SAME=0
done
eq "같은 입력 100회 → 같은 출력" "1" "$SAME"

# ============================================================ T2. 정적 검사
echo
echo "T2. 순수부 — 부수효과 없음 (정적 검사)"

# 이 검사 자체가 순수함수다: 코드 텍스트를 받아 위반 목록을 낸다.
# 원칙이 문서에만 남지 않게 하는 장치 — 순수해야 할 자리에 효과가 섞이면 여기서 멈춘다.
extract_fn() {
  awk -v fn="$1" '
    $0 ~ "^"fn"\\(\\) \\{" { inside = 1 }
    inside { print }
    inside && /^\}$/ { exit }
  ' "$LIB"
}
strip_benign() {
  grep -vE '^[[:space:]]*#' \
    | sed -E 's/\(\([^)]*\)\)/@ARITH@/g' \
    | sed -E 's/<<</@HERESTRING@/g'
}
FORBIDDEN_CMD='(^|[;&|(][[:space:]]*|^[[:space:]]*)(date|curl|wget|git|ssh|mktemp|touch|rm|mv|cp|mkdir|sed|awk|grep|cat|head|tail|source)([[:space:]]|$)'
FORBIDDEN_REDIR='[^@<>&[:space:]][[:space:]]*(>>?|<)[[:space:]]*[^&@[:space:]]'
FORBIDDEN_RANDOM='\$RANDOM|\$\{RANDOM'

T2_VIOL=0
# settings_resolve 는 완전히 순수해야 한다 — 외부 명령조차 부르지 않는다.
body="$(extract_fn settings_resolve)"
if [[ -z "$body" ]]; then
  fail "T2 — settings_resolve 본문을 못 찾음"; T2_VIOL=$(( T2_VIOL + 1 ))
else
  hits="$(printf '%s\n' "$body" | strip_benign \
    | grep -nE "$FORBIDDEN_CMD|$FORBIDDEN_REDIR|$FORBIDDEN_RANDOM" || true)"
  if [[ -n "$hits" ]]; then
    fail "T2 — settings_resolve 에 부수효과가 있음:"
    printf '%s\n' "$hits" | sed 's/^/      /'
    T2_VIOL=$(( T2_VIOL + 1 ))
  else
    ok "settings_resolve — 외부 명령·파일·시각·무작위 없음"
  fi
fi

# settings_lookup_json 은 파서를 부르되 디스크는 만지지 않아야 한다.
body="$(extract_fn settings_lookup_json)"
if [[ -z "$body" ]]; then
  fail "T2 — settings_lookup_json 본문을 못 찾음"; T2_VIOL=$(( T2_VIOL + 1 ))
else
  DISK='(^|[;&|(][[:space:]]*|^[[:space:]]*)(date|curl|wget|git|mktemp|touch|rm|mv|cp|mkdir|source)([[:space:]]|$)|\$RANDOM'
  hits="$(printf '%s\n' "$body" | strip_benign | grep -nE "$DISK" || true)"
  if [[ -n "$hits" ]]; then
    fail "T2 — settings_lookup_json 이 디스크/시각을 만짐:"
    printf '%s\n' "$hits" | sed 's/^/      /'
    T2_VIOL=$(( T2_VIOL + 1 ))
  else
    ok "settings_lookup_json — 디스크·시각·무작위 없음 (파서 호출만)"
  fi
fi

# 검사기 자체가 도는지 확인한다 — 통과만 하고 아무것도 안 보는 검사기는 무의미하다.
CANARY='canary() {
  local x
  x="$(date +%s)"
  cat /etc/hosts > /tmp/x
}'
canary_hits="$(printf '%s\n' "$CANARY" | strip_benign \
  | grep -cE "$FORBIDDEN_CMD|$FORBIDDEN_REDIR|$FORBIDDEN_RANDOM" || true)"
if [[ "${canary_hits:-0}" -ge 2 ]]; then
  ok "검사기 자체 확인 — 일부러 넣은 부수효과를 잡는다 (${canary_hits}건)"
else
  fail "T2 — 검사기가 부수효과를 못 잡는다 (canary ${canary_hits}건)"
  T2_VIOL=$(( T2_VIOL + 1 ))
fi
if [[ ${T2_VIOL} -eq 0 ]]; then echo "OK [T2]"; else echo "✖ [T2] 위반 ${T2_VIOL}건"; fi

# ============================================================ T1. JSON 조회
echo
echo "T1. JSON 조회 — 고정 입력, 고정 출력"

J='{"SCV_LANG":"korean","NUM":3,"YES":true,"BLANK":"","SPACED":"a b  c","UNI":"한글 값"}'
eq "문자열"            "korean"    "$(settings_lookup_json "$J" SCV_LANG)"
eq "숫자"              "3"         "$(settings_lookup_json "$J" NUM)"
eq "참거짓"            "true"      "$(settings_lookup_json "$J" YES)"
eq "빈 문자열"         ""          "$(settings_lookup_json "$J" BLANK)"
eq "공백 포함 원문"    "a b  c"    "$(settings_lookup_json "$J" SPACED)"
eq "유니코드 원문"     "한글 값"    "$(settings_lookup_json "$J" UNI)"
eq "없는 키"           ""          "$(settings_lookup_json "$J" NOPE)"
eq "중첩은 안 본다"    ""          "$(settings_lookup_json '{"a":{"b":1}}' a.b)"

J1="$(settings_lookup_json "$J" SCV_LANG)"
SAME=1
for _ in $(seq 1 50); do
  [[ "$(settings_lookup_json "$J" SCV_LANG)" == "$J1" ]] || SAME=0
done
eq "같은 입력 50회 → 같은 출력" "1" "$SAME"

# ============================================================ T8. 죽지 않는다
echo
echo "T8. 없거나 깨져도 죽지 않는다"

T8_OK=0
declare -a BAD=('' '{oops' '[1,2]' '"just a string"' '{"a":')
for b in "${BAD[@]}"; do
  out="$(settings_lookup_json "$b" X)"; rc=$?
  if [[ $rc -eq 0 && -z "$out" ]]; then T8_OK=$((T8_OK + 1))
  else fail "T8 — 입력 [$b] 에서 exit=$rc out=[$out]"; fi
done
eq "깨진 JSON 5가지 전부 조용히 빈 값" "5" "$T8_OK"

# 설정 파일이 없어도 기본값으로 간다
( cd "$WORK" && rm -f .env
  eq2() { [[ "$2" == "$3" ]] && ok "$1" || fail "$1 — expected [$2], got [$3]"; }
  : ) >/dev/null 2>&1
cd "$WORK"
rm -f .env
eq "파일 없음 → 기본값"   "fallback"  "$(settings_get NOTIFIER_PROVIDER fallback)"
: > .env
eq "빈 파일 → 기본값"     "fallback"  "$(settings_get NOTIFIER_PROVIDER fallback)"
printf 'JUNK LINE WITHOUT EQUALS\n#comment\n' > .env
eq "형식이 이상해도 죽지 않음" "fallback" "$(settings_get NOTIFIER_PROVIDER fallback)"

# 실제 읽기 + 우선순위
printf 'NOTIFIER_PROVIDER=slack\nQUOTED="korean"\nLAST=first\nLAST=second\n' > .env
eq "파일에서 읽음"        "slack"   "$(settings_get NOTIFIER_PROVIDER)"
eq "따옴표는 벗긴다"      "korean"  "$(settings_get QUOTED)"
eq "마지막 정의가 이긴다" "second"  "$(settings_get LAST)"
eq "환경변수가 파일을 이긴다" "discord" \
   "$(NOTIFIER_PROVIDER=discord bash -c 'source "'"$LIB"'"; settings_get NOTIFIER_PROVIDER')"

# 파일을 source 하지 않는다 — 사용자의 .env 가 스크립트를 죽이면 안 된다
printf 'DANGER=${UNSET_ON_PURPOSE}\nGOOD=fine\n' > .env
out="$(set -u; settings_get GOOD 2>/dev/null)"; rc=$?
if [[ $rc -eq 0 && "$out" == "fine" ]]; then
  ok "unset 변수를 참조하는 .env 가 있어도 nounset 아래에서 살아남는다"
else
  fail "T8 — .env 의 \${UNSET} 참조가 스크립트를 죽였다 (exit=$rc out=[$out])"
fi
cd "$REPO_ROOT"
[[ $FAIL -eq 0 ]] && echo "OK [T8]" || echo "✖ [T8]"

# ============================================================ 요약
echo
echo "─────────────────────────────"
echo "  통과 $PASS · 실패 $FAIL"
[[ $FAIL -eq 0 ]] && { echo "  ALL GATES OK"; exit 0; } || exit 1
