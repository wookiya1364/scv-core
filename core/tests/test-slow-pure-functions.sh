#!/usr/bin/env bash
# test-slow-pure-functions.sh — 느린 순수함수 17개를 고친 뒤에도 답이 같은지 본다
# (계획 20261111-wookiya1364-slow-pure-functions).
# 고치기 전 본문은 fixtures/slow-pure/reference.sh 에 ref_ 이름으로 있다. 같은 입력을 두 판에 넣어
# 출력과 끝 코드를 맞댄다.
#
# Run: bash core/tests/test-slow-pure-functions.sh
set -uo pipefail

CORE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
LIB="$CORE/scripts/lib"
for _l in text plan-link help-state model-prompting lang-enforce turn-check pure-catalog metrics regression-memo archive-search pure-bench; do
  # shellcheck disable=SC1090
  source "$LIB/$_l.sh"
done
# key_of 는 명령 파일 안에 있다 — 파일을 돌리지 않고 그 함수 글만 읽어 온다.
eval "$(LC_ALL=C awk '/^key_of\(\)[[:space:]]*\{/ { on = 1 } on { print } on && /^\}$/ { exit }' "$CORE/scripts/turn-check.sh")"
# shellcheck source=fixtures/slow-pure/reference.sh
source "$CORE/tests/fixtures/slow-pure/reference.sh"

PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✖ FAIL: $1"; FAIL=$((FAIL + 1)); }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# 함수 17개와 그 본문이 있는 파일
TABLE="scv_plan_conflict_after lib/plan-link.sh
scv_plan_conflict_before lib/plan-link.sh
scv_lint_lang_turn lib/help-state.sh
scv_lint_hangul_ratio lib/help-state.sh
scv_lint_strip_quoted lib/help-state.sh
scv_is_rewrite_quote lib/text.sh
scv_mp_answer_shows_rewrite lib/model-prompting.sh
scv_mp_scope_forbid lib/model-prompting.sh
scv_lang_drop_machine lib/lang-enforce.sh
scv_tc_words lib/turn-check.sh
scv_tc_receipt lib/turn-check.sh
key_of turn-check.sh
pc_duplicate_pairs lib/pure-catalog.sh
pc_mutual_pairs lib/pure-catalog.sh
scv_mx_aggregate lib/metrics.sh
scv_reg_split_chain lib/regression-memo.sh
scv_as_count_terms lib/archive-search.sh"

# chk <함수> <인자…> — 두 판에 같은 인자를 넣어 출력(끝의 줄바꿈까지)과 끝 코드를 맞댄다.
# 다르면 DIFF 를 올리고 첫 어긋남 하나를 FIRST 에 남긴다.
DIFF=0; RUNS=0; FIRST=""
chk() {
  local fn="$1" a b sa sb; shift
  a="$("ref_$fn" "$@" </dev/null 2>&1; s=$?; printf 'x'; exit $s)"; sa=$?
  b="$("$fn" "$@" </dev/null 2>&1; s=$?; printf 'x'; exit $s)"; sb=$?
  RUNS=$((RUNS + 1))
  if [[ "$a" != "$b" || $sa -ne $sb ]]; then
    DIFF=$((DIFF + 1))
    [[ -n "$FIRST" ]] || FIRST="인자 [$(printf '%q ' "$@" | cut -c1-160)] 옛 답 [${a:0:120}]($sa) 새 답 [${b:0:120}]($sb)"
  fi
}
# report <이름표> — 지금까지 모은 맞대기를 한 줄로 보고하고 셈을 비운다.
# SLOWPURE_TIMES=1 이면 그 묶음에 걸린 초를 함께 적는다(시험이 느려졌을 때 어디인지 보려고).
_T0=$SECONDS
report() {
  [[ "${SLOWPURE_TIMES:-}" == 1 ]] && { echo "    (${1}: $((SECONDS - _T0))초)"; }; _T0=$SECONDS
  if (( RUNS == 0 )); then fail "$1 — 맞댄 입력이 없다"
  elif (( DIFF == 0 )); then ok "$1 — 입력 ${RUNS}개에서 같음"
  else fail "$1 — 입력 ${RUNS}개 중 ${DIFF}개가 다름 · 첫 어긋남: $FIRST"; fi
  DIFF=0; RUNS=0; FIRST=""
}
# examples_of <파일> <함수> — 함수 바로 위 주석의 "# 예:" 줄에서 인자 쪽만 한 줄씩 낸다.
examples_of() {
  local ex
  LC_ALL=C awk -v fn="$2" '/^#/ { buf[n++] = $0; next } $0 ~ "^"fn"\\(\\)[[:space:]]*\\{" { for (i = 0; i < n; i++) print buf[i]; exit } { n = 0 }' "$1" \
    | sed -n 's/^# 예: //p' | while IFS= read -r ex; do
        pc_split_example "$ex" | cut -f1
      done
}

echo "T1. 사전 예시에서 두 판의 답이 같다"
while read -r fn file; do
  n=0
  while IFS= read -r args; do
    [[ -n "$args" ]] || continue
    eval "set -- $args" 2>/dev/null || continue
    chk "$fn" "$@"; n=$((n + 1))
  done <<< "$(examples_of "$CORE/scripts/$file" "$fn")"
  report "T1 $fn"
done <<< "$TABLE"

echo "T2. 큰 입력에서 두 판의 답이 같다"
# 첫 예시를 되풀이해 키운다(재는 명령과 같은 방법). 옛 본문이 너무 오래 걸리는 둘은 작은 배수로 본다.
scales_of() {
  case "$1" in
    scv_plan_conflict_after)  echo "25 50" ;;
    scv_plan_conflict_before) echo "8 16" ;;
    scv_lint_lang_turn)       echo "25 50" ;;
    *)                        echo "25 100" ;;
  esac
}
while read -r fn file; do
  first="$(examples_of "$CORE/scripts/$file" "$fn" | sed -n 1p)"
  for k in $(scales_of "$fn"); do
    big="$(pb_scale_args "$first" "$k")" || continue
    eval "set -- $big" 2>/dev/null || continue
    chk "$fn" "$@"
  done
  report "T2 $fn"
done <<< "$TABLE"

echo "T3. 모서리 입력에서 두 판의 답이 같다"
NL=$'\n'; TAB=$'\t'
LONGK="$(printf '가나다라마바사아자차 %.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)"
LONGE="$(printf 'the quick brown fox jumps %.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)"

PLAN_A="# 계획${NL}${NL}## Goals / Non-Goals${NL}${NL}- **Goals**${NL}  - 화면 만들기${NL}- **Non-Goals**${NL}  - 결제 한도 변경 안 함${NL}  - 가${NL}  - 래퍼 저장소 작업 금지.${NL}  - [a]* 무늬 글자?${NL}${NL}## Suggested path${NL}${NL}1. [x] core/a.sh 고침 — \`x\`${NL}2. core/a.sh 와 core/b.sh 손봄 — \`y\`${NL}3. 🔄 화면 만들기 — \`z\`${NL}4. ✅ 끝난 일 core/c.sh${NL}5. [!] 막힌 일 core/d d.sh${NL}6. 문서 docs/[a]*.md 고침${NL}7. 결제 한도 변경${NL}${NL}## Links"
PLAN_B="## Goals / Non-Goals${NL}- **Goals**${NL}  - 결제 한도 변경${NL}  - 화면 만들기.${NL}  - 가${NL}  - 래퍼 저장소 작업${NL}  - 무늬 글자${NL}  - 문서 docs/[a]*.md 고침 — 꼬리${NL}  - 아무 상관 없는 목표${NL}- **Non-Goals**${NL}  - 다"
for files in "" "core/a.sh" "core/a.sh${NL}core/c.sh" "core/a.sh${NL}${NL}core/b.sh${NL}" "core/a.sh${NL}core/a.sh" "core/d d.sh" "docs/[a]*.md" "*" "?" "core/" "없는/파일.sh${NL}core/b.sh" "a" " "; do
  chk scv_plan_conflict_after "$PLAN_A" "$files"
  chk scv_plan_conflict_after "## Steps${NL}1. core/a.sh${NL}2. [x] core/b.sh" "$files"
  chk scv_plan_conflict_after "" "$files"
  chk scv_plan_conflict_after "# 단계 없음" "$files"
done
report "T3 scv_plan_conflict_after"
for a in "$PLAN_A" "" "# a" "## Goals / Non-Goals${NL}- **Non-Goals**${NL}  - 가" "## Suggested path${NL}1. 화면 만들기${NL}2. [x] 결제 한도 변경${NL}3. 가나"; do
  for b in "$PLAN_B" "" "# b" "$PLAN_A" "## Goals / Non-Goals${NL}- **Goals**${NL}  - 가나다${NL}  - 화면${NL}  - *"; do
    chk scv_plan_conflict_before "$a" "$b"
  done
done
report "T3 scv_plan_conflict_before"

FENCE='```'
TURN="한국어 줄입니다 충분히 긴 한국어 문장${NL}This line is written in English only and is long${NL}  > quoted English line that should be skipped entirely${NL}| table | cell | english words here |${NL}${FENCE}${NL}code block English text that is long enough${NL}${FENCE}${NL}\`inline code only english words\` 그리고 한글${NL}[link text english words](https://example.com/a/b) see the docs page${NL}https://example.com/only/a/url/line/with/many/letters${NL}short en${NL}Mixed 한글 and English words in one line here${NL}${LONGE}${NL}${LONGK}"
for lang in korean ko english "" japanese; do
  chk scv_lint_lang_turn "Final answer written in English, long enough." "$TURN" "$lang"
  chk scv_lint_lang_turn "마지막 답은 한국어로 충분히 길게 썼습니다" "$TURN" "$lang"
  chk scv_lint_lang_turn "" "" "$lang"
  chk scv_lint_lang_turn "no newline at the end of this english text" "" "$lang"
  chk scv_lint_lang_turn "" "${FENCE}${NL}an unclosed fence hides everything below it${NL}English after the fence line stays hidden" "$lang"
  chk scv_lint_lang_turn "x" "tab${TAB}separated english words in a long line${NL}${NL}${NL}  indented English sentence with enough letters" "$lang"
  chk scv_lint_lang_turn "$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE 한글" "$LONGE$LONGK" "$lang"
done
report "T3 scv_lint_lang_turn"
for t in "" "a" "가" "abc가나다" "한글만 있는 글" "English only" "1234 !@#" "$LONGK" "$LONGE" "$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE$LONGE$LONGK" "$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGK$LONGE" "日本語のテキスト と 한글" "이모지 😀 와 한글 abc" "줄${NL}바꿈${NL}abc"; do
  chk scv_lint_hangul_ratio "$t"
done
chk scv_lint_hangul_ratio
report "T3 scv_lint_hangul_ratio"
for s in "" "a" 'say "hello" now' 'two "a" and "b" here' 'unbalanced "quote here' 'a (b) c (d (e) f) g' 'open ( only' 'close ) only' '“둥근 따옴표” 밖' '‘작은’ 그리고 “큰” 따옴표' '（전각 괄호） 밖' '“겹친 “안쪽” 따옴표” 끝' "여러 줄 \"안${NL}쪽\" 과 (괄${NL}호)" '"" () “” ‘’ （）' "$LONGK \"$LONGE\" ($LONGK) $LONGE" '((((깊은))))' '"a"b"c"d"'; do
  chk scv_lint_strip_quoted "$s"
done
report "T3 scv_lint_strip_quoted"
GT=$'\x3e'
for s in "" "$GT" "$GT **다시 쓴 요청**: 가" "  $GT **다시 쓴 요청**: 가" "${GT}다시 쓴 요청" "$GT _Rewritten request_: x" "$GT rewritten request" "$GT 書き直した依頼: あ" "다시 쓴 요청" "$GT 다른 인용" "$GT * _ * 다시 쓴 요청" "${TAB}$GT${TAB}**다시 쓴 요청**" "$GT $LONGK" "$LONGK $GT 다시 쓴 요청" "$GT **다시 쓴 요청**: $LONGK$LONGE$LONGK" "$GT${NL}다시 쓴 요청" "   " "$GT$GT 다시 쓴 요청"; do
  chk scv_is_rewrite_quote "$s"
done
report "T3 scv_is_rewrite_quote"
RW="지금까지 한 일을 저장소의 실제 상태로 확인해 보고한다."
for text in "" "$GT **다시 쓴 요청**: $RW${NL}본문" "본문만 있고 인용이 없다" "${FENCE}${NL}$GT **다시 쓴 요청**: 울타리 안${NL}${FENCE}${NL}본문" "$GT 지금까지 한 일을 저장소의 실제 상태로${NL}본문" "  $GT   지금까지   한 일을   저장소의 실제" "$GT Rewritten request: x" "$GT 다른 인용${NL}$GT 또 다른 인용" "${FENCE}${NL}닫히지 않은 울타리${NL}$GT **다시 쓴 요청**" "$LONGK${NL}$LONGE${NL}$GT $RW" "끝 줄바꿈 없음 $GT 다시 쓴 요청"; do
  for rw in "$RW" "" "   " "짧음" "$LONGK"; do
    chk scv_mp_answer_shows_rewrite "$text" "$rw"
  done
done
report "T3 scv_mp_answer_shows_rewrite"
for v in "" "변경 없음 — 보고만" "변경 없음" "변경없음: 조회" "변경 없음x" "  **범위:** 읽기만 한다" "Scope: No Changes" "SCOPE: READ-ONLY (docs)" "scope : no changes" "범위 : 변경 없음" "no changes except docs" "변경 없음 — 문서 말고" "No File Changes, only a report" "DO NOT CHANGE ANY FILES." "core/a.sh 를 고친다" "\`변경 없음\` — 보고" "__ 읽기 전용" "変更なし。" "何も変更しない（報告のみ）" "Report Only / status" "REPORT ONLYX" "변경 없음 OTHER THAN docs" "ÀÉÎ no changes" "$LONGE" "변경 없음 — $LONGK$LONGE" "ABCDEFGHIJKLMNOPQRSTUVWXYZ" "Z" "*" "\`"; do
  chk scv_mp_scope_forbid "$v"
done
report "T3 scv_mp_scope_forbid"
LT=$'\x3c'
for p in "" "기계 글 없음" "앞 ${LT}system-reminder${GT}속${LT}/system-reminder${GT} 뒤" "앞 ${LT}system-reminder${GT}닫히지 않음" "${LT}task-notification${GT}a${LT}/task-notification${GT}${LT}task-notification${GT}b${LT}/task-notification${GT}끝" "가 ${LT}command-name${GT}x${LT}/command-name${GT} 나 ${LT}command-args${GT}y${LT}/command-args${GT} 다" "${LT}system-reminder attr=\"1\"${GT}속${LT}/system-reminder${GT}뒤" "${LT}system-reminder${GT}겹 ${LT}system-reminder${GT}안${LT}/system-reminder${GT} 밖${LT}/system-reminder${GT} 끝" "${LT}/system-reminder${GT} 닫는 것만" "${LT}other-tag${GT}그대로${LT}/other-tag${GT}" "$LONGK ${LT}ci-monitor-event${GT}$LONGE${LT}/ci-monitor-event${GT} $LONGK" "${LT}local-command-stdout${GT}${NL}여러${NL}줄${NL}${LT}/local-command-stdout${GT}${NL}사람 글"; do
  chk scv_lang_drop_machine "$p"
done
report "T3 scv_lang_drop_machine"
for t in "" "a" "가" "결제 한도를 변경으로 화면에서 사용자에게" "the quick brown fox" "기능 추가 수정 변경 화면 단계 계획 사용자 하기 한다 있음 없음" "core/a.sh 와 core/b.sh 를 고침!" "100% 확인, 50%만" "별 * 물음표 ? 대괄호 [a] 중괄호 {x,y}" "탭${TAB}과${NL}줄바꿈" "은 는 이 가" "까지부터 에서으로" "$LONGK" "$LONGE $LONGK" "日本語 テキスト 한글과 English와 섞임" "   앞뒤 공백   " "하이픈-붙은-낱말 밑줄_낱말"; do
  chk scv_tc_words "$t"
done
report "T3 scv_tc_words"
for c in "" "bash /x/y/plan-link.sh progress slug --step 1" "cd /repo && bash \"/x y/plan-link.sh\" append s" "cd /repo; A=1 B=2 bash /p/plan-link.sh exempt --kind release" "  bash /p/plan-link.sh pause" "bash /p/plan-link.sh resume${NL}둘째 줄" "bash /p/plan-link.sh progressx" "bash plan-link.sh progress" "echo bash /p/plan-link.sh progress" "bash /p/other.sh progress" "$LONGE bash /p/plan-link.sh append" "cd $LONGE && bash /p/plan-link.sh append x" "bash /p/plan-link.sh append $LONGK"; do
  chk scv_tc_receipt "$c"
done
report "T3 scv_tc_receipt"
for k in "" "a" "a/b" "a b/c d" "scv/promote/20261111-x" "/" "//" " / " "한글/경로 이름" "a_b/c" "$LONGK/$LONGE" "끝/"; do
  chk key_of "$k"
done
report "T3 key_of"
for l in "" "k1${TAB}a${NL}k1${TAB}b${NL}k2${TAB}c" "k${TAB}a${NL}k${TAB}b${NL}k${TAB}c${NL}k${TAB}d" "k1${TAB}a${NL}k2${TAB}b" "k${TAB}a${NL}이름 없음${NL}k${TAB}b${NL}${NL}k${TAB}" "k${TAB}a${NL}k${TAB}a" "${TAB}a${NL}${TAB}b" "k${TAB}a${TAB}더${NL}k${TAB}b" "가${TAB}함수1${NL}나${TAB}함수2${NL}가${TAB}함수3${NL}나${TAB}함수4${NL}가${TAB}함수5"; do
  chk pc_duplicate_pairs "$l"
done
report "T3 pc_duplicate_pairs"
for l in "" "a${TAB}b${NL}b${TAB}a" "a${TAB}b${NL}c${TAB}d" "a${TAB}b${NL}b${TAB}a${NL}a${TAB}b" "a${TAB}a" "a${TAB}a${NL}a${TAB}a" "a${TAB}b${NL}b${TAB}a${NL}b${TAB}c${NL}c${TAB}b${NL}c${TAB}a" "a${NL}b${TAB}a${NL}a${TAB}b${NL}${NL}x${TAB}" "가${TAB}나${NL}나${TAB}가${NL}다${TAB}가${NL}가${TAB}다${NL}나${TAB}가"; do
  chk pc_mutual_pairs "$l"
done
report "T3 pc_mutual_pairs"
for l in "" "a${TAB}3" "a${TAB}3${NL}b${TAB}1${NL}c${TAB}2" "a${TAB}3${NL}b${TAB}1${NL}c${TAB}2${NL}d${TAB}10" "a${TAB}x${NL}b${TAB}${NL}c" "a${TAB}5${NL}${NL}b${TAB}5${NL}" "a${TAB}9${NL}b${TAB}8${NL}c${TAB}7${NL}d${TAB}6${NL}e${TAB}5${NL}f${TAB}4${NL}g${TAB}3${NL}h${TAB}2${NL}i${TAB}1" "a${TAB}0${NL}b${TAB}0" "a${TAB}007${NL}b${TAB}10" "a${TAB}-1${NL}b${TAB}2" "a${TAB}1${TAB}더${NL}b${TAB}2" "끝 줄바꿈 없음${TAB}4" "a${TAB}2${NL}b${TAB}2${NL}c${TAB}2${NL}d${TAB}1${NL}e${TAB}3${NL}f${TAB}2"; do
  chk scv_mx_aggregate "$l"
done
report "T3 scv_mx_aggregate"
for l in "" "a" "a && b" "a && b; c || d" "a&&b;c||d" "a ;; b" "&&" "a &&" "; a" "a | b" "a & b" "echo 'x && y'; z" 'echo "x; y" && z' "한글 명령 && 다른 명령; 끝" "$LONGE && $LONGK; $LONGE || $LONGK" "a &&& b" "a ||| b" "a;b;c;d;e;f" "   "; do
  chk scv_reg_split_chain "$l"
done
report "T3 scv_reg_split_chain"
for line in "" "Refund Button 환불 버튼" "the QUICK brown fox" "한글만 있는 줄" "$LONGE $LONGK"; do
  for terms in "" "refund" "Refund${NL}button${NL}환불" "QUICK${NL}quick${NL}Quick" "없는말${NL}${NL}fox${NL}" "*${NL}?${NL}[a]" "버튼${NL}버튼${NL}버튼" "the quick${NL}BROWN FOX" "É${NL}é"; do
    chk scv_as_count_terms "$line" "$terms"
  done
done
report "T3 scv_as_count_terms"

echo
echo "Total: $((PASS + FAIL)) · Pass: $PASS · Fail: $FAIL"
[[ $FAIL -eq 0 ]]
