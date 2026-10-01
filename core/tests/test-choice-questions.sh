#!/usr/bin/env bash
# test-choice-questions.sh — "결정은 고르는 선택지로" 검사 (v0.64.0+).
#
# 왜 있나: 호스트 설정에 선택지 도구가 있으면 SCV 가 사용자에게 고르게 하는 결정은 그 도구로 묻는다 — 매 턴 안내 한 줄이
# 실리고, 마지막 답이 글로 묻거나 번호로 고르게 하면서 끝나면 종료 훅이 같은 턴에 한 번 막는다(이미 계속 중이면 다음 턴
# 경고). 도구가 없으면(기본 · 코덱스) 모든 출력과 판정이 이 기능 전과 같다. 규칙은 contracts/choices.md 한 곳뿐이다.
#
# Covers TESTS.md T1~T9 · T13~T15 of 20261001-wookiya1364-restore-choice-questions
#   and T19 · T20 (등록 판정 경로 — 답 모양 검사 경로의 T19 는 test-answer-lint-source [T11]).
#   (T16 = test-host-neutral · test-model-prompting · test-help-budget, T21 · T22 = test-model-prompting,
#    T10~T12 · T17 · T18 = 설치본 · CI 실측).
# 픽스처는 중립 도구 이름(PickTool)만 쓴다 — 코어에는 호스트 도구 이름을 적지 않는다.
# Run: bash core/tests/test-choice-questions.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE=""
for up in "$HERE/.." "$HERE/../.."; do
  for sub in core vendor/scv-core/core plugins/scv/vendor/scv-core/core; do
    if [[ -f "$up/$sub/scripts/lib/settings.sh" ]]; then CORE="$(cd "$up/$sub" && pwd)"; break 2; fi
  done
done
[[ -n "$CORE" ]] || { echo "test-choice-questions: payload not found from $HERE" >&2; exit 1; }
PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✖ FAIL: $1"; FAIL=$((FAIL + 1)); }
LIB="$CORE/scripts/lib/choices.sh"; GATE="$CORE/scripts/choice-gate.sh"; MP="$CORE/scripts/model-prompting.sh"
PROMPT_HOOK="$CORE/template/hooks/on-user-prompt.sh"; STOP_HOOK="$CORE/template/hooks/on-stop.sh"
RULE="$CORE/contracts/choices.md"; FIX="$CORE/tests/fixtures/model-prompting"
for f in "$LIB" "$GATE" "$PROMPT_HOOK" "$STOP_HOOK" "$RULE" "$FIX/profile.env" "$FIX/guides/INDEX.tsv"; do
  [[ -f "$f" ]] || { echo "✖ 없음: $f"; exit 1; }
done
command -v jq >/dev/null 2>&1 || { echo "jq 없음 — 이 검사는 jq 가 필요하다" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/scv-choice.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
{ cat "$FIX/profile.env"; printf 'SCV_CHOICE_TOOL=PickTool\n'; } > "$WORK/profile-pick.env"
cp "$FIX/profile.env" "$WORK/profile-none.env"
# 등록 판정까지 켠 프로필 — 요구 항목 목록 · 자동 알림 태그 · 선택지 도구.
cp -R "$FIX/guides" "$WORK/guides-cl"
printf '# source: common.md\ngoal\tState the goal\tfixture quote a\nfinish\tState the done condition\tfixture quote b\n' > "$WORK/guides-cl/checklist-common.tsv"
printf '# source: model-a.md\nfinish\tState the done condition precisely\tfixture quote c\nsources\tName the sources to check\tfixture quote d\n' > "$WORK/guides-cl/checklist-model-a.tsv"
{ cat "$FIX/profile.env"; printf 'SCV_PROMPTING_GUIDES=%s\nSCV_AUTO_PROMPT_TAGS=machine-event\nSCV_CHOICE_TOOL=PickTool\n' "$WORK/guides-cl"; } > "$WORK/profile-full.env"
SUB_OK="$(printf 'goal | msg | fix the login bug\nfinish | ctx | conversation turn 2: the test passes\nsources | asked | which log file? (recommended: app.log)\nrewrite | - | Fix the login bug until the login test passes')"
QUOTE=$'> **Rewritten request**: Fix the login bug until the login test passes'

new_repo() {  # <이름> → 빈 scv 저장소 경로 (세션 s1 의 help 표식 포함)
  local d="$WORK/$1"; mkdir -p "$d/scv/journal"
  printf '{"session":"s1","protocol":1,"turn":3,"diag":"","diag_at":"","nonce":"abcd1234"}\n' > "$d/scv/journal/.help-state"
  printf '%s' "$d"
}
asks() { bash -c 'source "$1"; scv_asks_in_text "$(scv_answer_body "$2")"' _ "$LIB" "$1"; }
hook_p() {  # <저장소> <프로필> <프롬프트> [코어] → 매 턴 훅 출력
  local core="${4:-$CORE}"
  (cd "$1" && jq -cn --arg p "$3" '{prompt:$p,session_id:"s1"}' \
     | SCV_CORE_ROOT="$core" SCV_HOST_PROFILE="$2" bash "$core/template/hooks/on-user-prompt.sh" 2>/dev/null)
}
stop_p() {  # <저장소> <프로필> <마지막 답> <계속 중 true|false> [코어] → 종료 훅 stdout
  local r="$1" core="${5:-$CORE}" tr="$WORK/tr-$RANDOM$RANDOM.jsonl"
  printf '{"type":"user","message":{"content":[{"type":"text","text":"q"}]}}\n' > "$tr"
  jq -cn --arg t "$3" '{type:"assistant",message:{model:"vendor-model-a",content:[{type:"text",text:$t}]}}' >> "$tr"
  (cd "$r" && jq -cn --arg p "$tr" --arg a "$3" --argjson act "$4" '{transcript_path:$p,last_assistant_message:$a,stop_hook_active:$act}' \
     | SCV_CORE_ROOT="$core" SCV_HOST_PROFILE="$2" GIT_AUTHOR_NAME="Hook User" bash "$core/template/hooks/on-stop.sh" 2>/dev/null)
}
reg_full() { (cd "$1" && printf '%s\n' "$SUB_OK" | SCV_HOST_PROFILE="$WORK/profile-full.env" bash "$MP" register --model vendor-model-a 2>/dev/null); }

# 픽스처 — 잡을 것(T1)과 잡지 않을 것(T2)
C_A=$'| # | 질문 | 내 추천 |\n|---|---|---|\n| 1 | 계획 폴더 이름 | restore-choice |\n\n\'다 추천대로\'라고 하시거나, 바꿀 번호만 알려 주세요.'
C_B=$'남은 것: 커밋 안 된 기록 2개.\n질문: 세 로컬 작업 폴더를 개발 브랜치 최신으로 옮겨 둘까요? (추천: 예)'
C_C=$'| # | 질문 | 추천 |\n|---|---|---|\n| 1 | 릴리스 | 예 |\n\n번호로 답해 주세요.'
C_D1=$'Two decisions are open.\n\nReply with the numbers.'
C_D2=$'Please answer by number.'
C_E=$'All tests passed.\n\nShould I proceed?'
N_A=$'| 단위 | 해결책 | 추천 |\n|---|---|---|\n| 판정 | ①순수 함수 | ① 재사용 |\n\n| 단계 | 결과 |\n|---|---|\n| 검사 | 통과 |\n\n| 번호 | 위치 | 조건 | 깨지는 것 | 확인 |\n|---|---|---|---|---|\n| P1 | a.sh:3 | 빈 값 | 없음 | 확인 |'
N_B=$'결론입니다.\n\n> **다시 쓴 요청**: 다 끝난거 맞아? 지금 상태를 알려 줘.\n\n남은 것은 없습니다.'
N_C=$'설명입니다.\n\n```\necho "ok?"\n```\n\n끝났습니다.'
N_D=$'고르지 않으셔서 여기서 멈춥니다.'
N_E=$'왜 그럴까? 원인은 설정이다.\n\n그래서 고쳤습니다.'

echo "── [T1] 글로 묻는 답 판정 — 잡을 것 ──"
c=0
# 독립 검토가 찾은 누락 모양: 질문 뒤 보기 목록 · 요청형("정해 주세요" · "Let me know which") · 이모티콘 · 괄호 · 굵은 괄호 · 따옴표
C_F1=$'어떻게 진행할까요?\n\n1. A 방식 (추천)\n2. B 방식'
C_F2=$'Which approach do you prefer?\n- Option A (recommended)\n- Option B'
C_F3='…어느 쪽으로 할지 정해 주세요.'
C_F4='Let me know which one you want.'
C_F5='진행할까요? 🙂'
C_F6='(이대로 진행할까요?)'
C_F7='Ready to merge? :)'
C_F8='진행할까요? **(추천: 예)**'
C_F9=$'Done.\n\nShall I \xe2\x80\x9cship it?\xe2\x80\x9d'
for x in "$C_A" "$C_B" "$C_C" "$C_D1" "$C_D2" "$C_E" "$C_F1" "$C_F2" "$C_F3" "$C_F4" "$C_F5" "$C_F6" "$C_F7" "$C_F8" "$C_F9"; do
  [[ "$(asks "$x")" == 1 ]] && c=$((c + 1)) || echo "      ✖ not caught: $(head -c 60 <<<"$x")"
done
[[ $c -eq 15 ]] && ok "화면 문구 · (추천: 예) · 번호로 답 · 영어 · 물음표 끝 + 검토 누락 9 모양 — 15/15" || fail "T1 $c/15"
c=0
for L in C en_US.UTF-8; do [[ "$(LC_ALL=$L bash -c 'source "$1"; scv_asks_in_text "$2"' _ "$LIB" "$C_F9")" == 1 ]] && c=$((c + 1)); done
[[ $c -eq 2 ]] && ok "로캘과 무관 — C · UTF-8 같은 판정" || fail "T1 로캘 $c/2"

echo "── [T2] 글로 묻는 답 판정 — 잡지 않을 것 ──"
c=0
# 독립 검토가 찾은 오탐 모양: 되짚는 표 · 상태 표의 물음표 · 평서문 속 "추천대로" · "番号だけ" · "번호로 골라 주신" · "pick a number"
N_F1=$'| 질문 | 고른 것 |\n|---|---|\n| 릴리스할까? | 예 |'
N_F2=$'| 항목 | 상태 |\n|---|---|\n| 원격 CI | ? |'
N_F3='말씀하신 대로 다 추천대로 반영했습니다.'
N_F4='バージョン番号だけ上げました。'
N_F5='번호로 골라 주신 2번으로 바꿨습니다.'
N_F6='The script will pick a number between 1 and 10.'
N_F7=$'바꾼 것:\n- a\n- b'
for x in "$N_A" "$N_B" "$N_C" "$N_D" "$N_E" "$N_F1" "$N_F2" "$N_F3" "$N_F4" "$N_F5" "$N_F6" "$N_F7"; do
  [[ "$(asks "$x")" == 0 ]] && c=$((c + 1)) || echo "      ✖ wrongly caught: $(head -c 60 <<<"$x")"
done
[[ $c -eq 12 ]] && ok "정보 표 · 인용 · 코드 · 평서문 · 중간 물음표 + 검토 오탐 7 모양 — 12/12" || fail "T2 $c/12"
if [[ -f "$CORE/scripts/check-purity.sh" ]]; then
  o="$(bash "$CORE/scripts/check-purity.sh" "$LIB" "$CORE/scripts/lib/help-state.sh" 2>&1)"
  grep -q '^OK  purity' <<<"$o" && ok "순수성 계약 통과 (판정 함수 · 턴 끝 메시지)" || fail "순수성: $(head -2 <<<"$o")"
fi

echo "── [T3] 막기 판정 — 순수 함수 ──"
g() { bash -c 'source "$1"; scv_choice_gate "$2" "$3" "$4"' _ "$LIB" "$@"; }
c=0
[[ "$(g 1 PickTool 0)" == block ]] && c=$((c + 1)) || echo "      (1,PickTool,0)"
[[ "$(g 1 PickTool 1)" == warn ]] && c=$((c + 1)) || echo "      (1,PickTool,1)"
[[ "$(g 0 PickTool 0)" == ok && "$(g 0 PickTool 1)" == ok ]] && c=$((c + 1)) || echo "      (0,PickTool,*)"
[[ "$(g 1 '' 0)" == ok && "$(g 1 '' 1)" == ok ]] && c=$((c + 1)) || echo "      (1,'',*)"
[[ $c -eq 4 ]] && ok "block · warn · ok · 도구 없음 ok — 4/4" || fail "T3 $c/4"

echo "── [T4] 종료 훅 — 등록을 마친 사람 턴이 글로 묻고 끝나면 같은 턴에 한 번 막는다 ──"
R="$(new_repo t4)"; hook_p "$R" "$WORK/profile-full.env" "로그인 고쳐" >/dev/null; reg_full "$R" >/dev/null
o="$(stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s\n\n%s' "결론." "$QUOTE" "$C_A")" false)"
if [[ "$(jq -r .decision <<<"$o" 2>/dev/null)" == block ]] && grep -q 'SCV 선택지' <<<"$o" && grep -q 'PickTool' <<<"$o" \
   && grep -q '첫 보기가 추천' <<<"$o" && grep -q '4개를 넘으면' <<<"$o"; then ok "첫 번째: 막음 — 이유에 도구 이름 · 추천 첫 보기 · 나누기"; else fail "T4 첫 번째: [$o]"; fi
rm -f "$R/scv/journal/.help-warn"
o="$(stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s\n\n%s' "결론." "$QUOTE" "$C_A")" true)"
[[ -z "$o" ]] && grep -q '^\[SCV 가이드\] 직전 턴: \[SCV 선택지\]' "$R/scv/journal/.help-warn" 2>/dev/null \
  && ok "이미 계속 중: 막지 않고 다음 턴 경고" || fail "T4 계속 중: [$o] / $(cat "$R/scv/journal/.help-warn" 2>/dev/null)"
(cd "$R" && bash "$CORE/scripts/help-state.sh" reset >/dev/null 2>&1)
grep -q '^\[SCV 가이드\] 직전 턴: \[SCV 선택지\]' "$R/scv/journal/.help-warn" 2>/dev/null \
  && ok "경고는 컨텍스트 초기화(clear · 압축 · 재개) 뒤에도 남는다" || fail "T4 초기화 뒤 경고 사라짐"
o="$(stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s' "결론." "$C_A")" false)"
grep -q 'SCV 프롬프트' <<<"$o" && ! grep -q 'SCV 선택지' <<<"$o" && ok "등록 · 인용 판정이 먼저 막으면 선택지 판정은 보지 않는다(한 번에 한 이유)" \
  || fail "T4 한 이유: [$o]"

echo "── [T5] 종료 훅 — 자동 알림 턴에도 적용된다 ──"
R="$(new_repo t5)"; hook_p "$R" "$WORK/profile-full.env" "로그인 고쳐" >/dev/null; reg_full "$R" >/dev/null
stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s\n\n%s' "결론." "$QUOTE" "끝났습니다.")" false >/dev/null   # 사람 턴이 끝난다
hook_p "$R" "$WORK/profile-full.env" $'<machine-event>\n<status>completed</status>\n</machine-event>' >/dev/null
gate_auto="$(cd "$R" && printf '%s' "$C_B" | SCV_HOST_PROFILE="$WORK/profile-full.env" bash "$MP" stop --active 0 2>/dev/null | grep '^STOP_GATE')"
o="$(stop_p "$R" "$WORK/profile-full.env" "$C_B" false)"
[[ "$gate_auto" == "STOP_GATE: auto" ]] && [[ "$(jq -r .decision <<<"$o" 2>/dev/null)" == block ]] && grep -q 'SCV 선택지' <<<"$o" \
  && ok "등록 판정은 auto 로 건너뛰고, 선택지 판정은 막는다" || fail "T5: gate=[$gate_auto] out=[$o]"

echo "── [T6] 종료 훅 — 정보만 준 턴 · 선택지로 물은 뒤 평서문으로 끝난 턴은 통과 ──"
R="$(new_repo t6)"; c=0
for x in "$N_A" "$N_B" "$N_C" "$N_D" "$N_E" "고르신 대로 진행합니다. 결과는 끝에 정리하겠습니다."; do
  o="$(stop_p "$R" "$WORK/profile-pick.env" "$x" false)"; [[ -z "$o" ]] && c=$((c + 1)) || echo "      ✖ blocked: $(head -c 50 <<<"$x") → $o"
done
[[ $c -eq 6 ]] && ok "막지 않음 — 6/6" || fail "T6 $c/6"

echo "── [T7] 도구가 없으면 지금과 같다 (코덱스 · 기본) ──"
# 같은 훅을 도구 없음 · 도구 있음으로 돌린다 — 차이는 안내 한 줄뿐이어야 한다(도구가 없으면 그 줄도 없다).
R1="$(new_repo t7a)"; R2="$(new_repo t7b)"
# 진단 줄의 저장소 경로는 폴더 이름만 다르다(임시 경로의 // 는 출력에서 / 로 접힌다) — 이름만 맞춘다.
o1="$(hook_p "$R1" "$WORK/profile-none.env" "안녕" | sed -E 's#/t7[ab]\)#/REPO)#g')"
o2="$(hook_p "$R2" "$WORK/profile-pick.env" "안녕" | sed -E 's#/t7[ab]\)#/REPO)#g' | grep -v '^\[SCV choices\] ')"
[[ "$o1" == "$o2" ]] && ! grep -q 'SCV choices' <<<"$o1" && ok "매 턴 훅: 도구가 없으면 안내 줄이 없고, 나머지 출력은 도구가 있을 때와 같다" || fail "T7 매 턴 훅 출력: $(diff <(printf '%s' "$o1") <(printf '%s' "$o2") | head -5)"
[[ -z "$(cd "$R1" && SCV_HOST_PROFILE="$WORK/profile-none.env" bash "$GATE" line 2>/dev/null)" ]] && ok "안내 한 줄 없음" || fail "T7 안내 줄이 있다"
c=0
for x in "$C_A" "$C_B" "$C_C" "$C_D1" "$C_E"; do o="$(stop_p "$R1" "$WORK/profile-none.env" "$x" false)"; [[ -z "$o" ]] && c=$((c + 1)); done
[[ $c -eq 5 ]] && ok "글로 물어도 선택지 판정으로 막지 않는다 — 5/5" || fail "T7 막음 $c/5"

echo "── [T8] 앞쪽 안내 — 도구가 있을 때만 한 줄, 자동 알림 턴에도 ──"
line="$(bash -c 'source "$1"; scv_choice_line PickTool' _ "$LIB")"
c=0
for k in "PickTool" "recommended option first" "avoids its own problems" "over 4 questions" "over 4 options" "names, suggested values" "cancelled, stop" "contracts/choices.md"; do
  [[ "$line" == *"$k"* ]] && c=$((c + 1)) || echo "      line lacks: $k"
done
[[ -z "$(bash -c 'source "$1"; scv_choice_line ""' _ "$LIB")" ]] && c=$((c + 1)) || echo "      empty tool must print nothing"
[[ $c -eq 9 ]] && ok "순수부: 요지 8개 + 도구 없으면 빈 값" || fail "T8 순수부 $c/9"
R="$(new_repo t8)"
o="$(hook_p "$R" "$WORK/profile-pick.env" "안녕")"
[[ "$(grep -c '^\[SCV choices\] Ask the user.s decisions with PickTool' <<<"$o")" == 1 ]] && ok "사람 턴: 한 줄 실림" || fail "T8 사람 턴: $(head -3 <<<"$o")"
R="$(new_repo t8b)"; hook_p "$R" "$WORK/profile-full.env" "로그인 고쳐" >/dev/null; reg_full "$R" >/dev/null
stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s' "$QUOTE" "끝.")" false >/dev/null
o="$(hook_p "$R" "$WORK/profile-full.env" $'<machine-event>\n<status>completed</status>\n</machine-event>')"
grep -q '^\[SCV choices\]' <<<"$o" && ! grep -q 'SCV 프롬프트' <<<"$o" && ok "자동 알림 턴: 안내는 실리고 등록 안내는 없다" || fail "T8 자동 턴: $o"

echo "── [T9] 규칙은 한 곳에, 나머지는 가리키기만 ──"
RULE_FLAT="$(tr '\n' ' ' < "$RULE" | tr -s ' ')"   # 문서의 줄바꿈이 문구를 끊지 않게
c=0
for k in "One decision is one question" "The recommended option comes first" "how it avoids the problems it would cause" \
         "consecutive calls, the most important first" "two steps" "one or two recommended values" \
         "do not go ahead on the recommendation" "Never end a turn by asking in text" "automatic-notification" \
         "When the host names none" "numbered table"; do
  [[ "$RULE_FLAT" == *"$k"* ]] && c=$((c + 1)) || echo "      rule lacks: $k"
done
hits="$(grep -rlF 'One decision is one question' "$CORE" 2>/dev/null | grep -vxF "$RULE" | grep -v '/tests/' || true)"
[[ -z "$hits" ]] && c=$((c + 1)) || echo "      rule text also in: $hits"
for f in protocols/regression.md contracts/host-profile.md contracts/rewrite-principle.md; do
  grep -qF 'contracts/choices.md' "$CORE/$f" && c=$((c + 1)) || echo "      no pointer in $f"
done
for k in 'protocols/help.md' 'protocols/help/full.md' 'protocols/regression.md' 'plain-language' 'Question: … options:' 'resolution order 2' 'renewed with that wording on 2026-10-01'; do
  grep -qF "$k" "$RULE" && c=$((c + 1)) || echo "      precedence lacks: $k"
done
# 도움말 답 모양의 결정 자리가 규칙을 직접 적는다(사용자 결정 2026-10-01 — 잠금은 새 문구로 다시 걸었다).
SHAPE="$(awk '/^## Answer shape/{f=1} f&&/^## /&&!/^## Answer shape/{exit} f' "$CORE/protocols/help.md" | tr '\n' ' ' | tr -s ' ')"
[[ "$SHAPE" == *"When the host names a choice tool, ask each decision through it instead"* && "$SHAPE" == *"core/contracts/choices.md"* ]] \
  && c=$((c + 1)) || echo "      help answer shape does not state the choice rule"
[[ "$SHAPE" == *"with a choice tool, one call of up to four questions"* ]] && c=$((c + 1)) || echo "      help answer shape lacks the four-per-call clause"
[[ $c -eq 24 ]] && ok "규칙 요소 11 · 한 곳뿐 · 가리키기 3 · 대체 선언 7 · 도움말 결정 자리 직접 2 — 24/24" || fail "T9 $c/24"

echo "── [T13] 취소 · 무응답 — 멈추고 추천으로 진행하지 않는다 ──"
grep -qF 'Cancelled or unanswered: do not go ahead on the recommendation' "$RULE" && grep -qF 'without ending on a question' "$RULE" \
  && [[ -z "$(stop_p "$(new_repo t13)" "$WORK/profile-pick.env" "$N_D" false)" ]] \
  && ok "규칙 문장 + 평서문으로 멈춘 답은 막히지 않는다" || fail "T13"

echo "── [T14] 단계 밖 질문 — 작업 끝의 '다음에 무엇을 할까요?' ──"
o="$(stop_p "$(new_repo t14)" "$WORK/profile-pick.env" $'작업을 마쳤습니다.\n\n다음에 무엇을 할까요?' false)"
[[ "$(jq -r .decision <<<"$o" 2>/dev/null)" == block ]] && grep -q 'PickTool' <<<"$o" && ok "막고 이유에 도구 이름" || fail "T14: [$o]"

echo "── [T15] 회귀 삭감 — 선택지로, CI 모드는 묻지 않는다 ──"
REG="$CORE/protocols/regression.md"; c=0
grep -qF 'the triage goes through it instead (`core/contracts/choices.md`)' "$REG" && c=$((c + 1)) || echo "      Never-list pointer missing"
grep -qF 'one question per failed slug with the three verdicts as options' "$REG" && c=$((c + 1)) || echo "      Step 2 pointer missing"
grep -qF -- '--ci` mode must NOT ask interactive questions' "$REG" && c=$((c + 1)) || echo "      --ci rule changed"
grep -qF 'one decisions table' "$REG" && grep -qF 'replaces the earlier' "$REG" && c=$((c + 1)) || echo "      rule-constitution phrases changed"
[[ $c -eq 4 ]] && ok "가리키기 둘 + CI 규칙 · 대체 선언 그대로 — 4/4" || fail "T15 $c/4"

# ---------------------------------------------------------------- 종료 훅의 턴 자르기 (두 번째 결함)
jl_user() { jq -cn --arg t "$1" '{type:"user",message:{content:[{type:"text",text:$t}]}}'; }
jl_meta() { jq -cn --arg t "$1" '{type:"user",isMeta:true,message:{content:[{type:"text",text:$t}]}}'; }
jl_asst() { jq -cn --arg t "$1" '{type:"assistant",message:{model:"vendor-model-a",content:[{type:"text",text:$t}]}}'; }
jl_tool() { printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}' '{"type":"user","message":{"content":[{"type":"tool_result","content":"x"}]}}'; }
stop_tr() {  # <저장소> <프로필> <원본> <마지막 답> → 종료 훅 stdout
  (cd "$1" && jq -cn --arg p "$3" --arg a "$4" '{transcript_path:$p,last_assistant_message:$a,stop_hook_active:false}' \
     | SCV_CORE_ROOT="$CORE" SCV_HOST_PROFILE="$2" GIT_AUTHOR_NAME="Hook User" bash "$STOP_HOOK" 2>/dev/null)
}
fresh_turn() {  # <이름> → 등록까지 마친 사람 턴의 저장소
  local r; r="$(new_repo "$1")"; hook_p "$r" "$WORK/profile-full.env" "로그인 고쳐" >/dev/null; reg_full "$r" >/dev/null; printf '%s' "$r"
}

echo "── [T19] 턴 자르기 — 내부 메시지 뒤에 끝나도 앞서 보인 인용을 인정한다 ──"
R="$(fresh_turn t19)"; TR="$WORK/t19.jsonl"
{ jl_user "로그인 고쳐"; jl_asst "$(printf '결론.\n\n%s' "$QUOTE")"; jl_meta "Base directory for this skill: /x"; jl_tool; jl_asst "끝났습니다."; } > "$TR"
o="$(stop_tr "$R" "$WORK/profile-full.env" "$TR" "끝났습니다.")"
[[ -z "$o" ]] && ok "내부 메시지(스킬 불러오기)는 경계가 아니다 — 막지 않음" || fail "T19 (a): [$o]"
R="$(fresh_turn t19b)"; TR="$WORK/t19b.jsonl"
{ jl_user "로그인 고쳐"; jl_asst "$(printf '결론.\n\n%s' "$QUOTE")"; jl_user "다음"; jl_tool; jl_asst "끝났습니다."; } > "$TR"
o="$(stop_tr "$R" "$WORK/profile-full.env" "$TR" "끝났습니다.")"
[[ "$(jq -r .decision <<<"$o" 2>/dev/null)" == block ]] && grep -q '인용' <<<"$o" && ok "진짜 사람 프롬프트는 지금처럼 경계 — 그 뒤에 인용이 없으면 막는다" || fail "T19 (b): [$o]"

echo "── [T20] 긴 턴 — 원본 창(400줄)을 넘어도 이번 사람 턴의 인용을 인정한다 ──"
R="$(fresh_turn t20)"; TR="$WORK/t20.jsonl"
{ jl_user "로그인 고쳐"; jl_asst "$(printf '결론.\n\n%s' "$QUOTE")"; for i in $(seq 1 230); do jl_tool; done; jl_asst "끝났습니다."; } > "$TR"
o="$(stop_tr "$R" "$WORK/profile-full.env" "$TR" "끝났습니다.")"
[[ "$(wc -l < "$TR" | tr -d ' ')" -gt 400 && -z "$o" ]] && ok "$(wc -l < "$TR" | tr -d ' ')줄 턴: 창을 넓혀 경계를 찾고 막지 않음" || fail "T20 (a): [$o]"
R="$(fresh_turn t20b)"; TR="$WORK/t20b.jsonl"
{ for i in $(seq 1 230); do jl_tool; done; jl_asst "끝났습니다."; } > "$TR"
o="$(stop_tr "$R" "$WORK/profile-full.env" "$TR" "끝났습니다.")"
[[ "$(jq -r .decision <<<"$o" 2>/dev/null)" == block ]] && grep -q 'turn-boundary=not-found' "$R/scv/journal/.help-drift" 2>/dev/null \
  && ok "경계를 끝내 못 찾으면 지금처럼(마지막 메시지만) 판정하고, 판정 기록에 남긴다" || fail "T20 (b): [$o] / $(tail -2 "$R/scv/journal/.help-drift" 2>/dev/null)"

# ---------------------------------------------------------------- 문제 표 · 문제 칸 막기 (세 번째 요구)
echo "── [T23] 문제 표 · '생길 수 있는 문제' 칸 — 판정 (세 언어) ──"
MPLIB="$CORE/scripts/lib/model-prompting.sh"
pt() { bash -c 'source "$1"; scv_mp_answer_has_problem_table "$2"' _ "$MPLIB" "$1"; }
c=0
for x in "| 단위 | 해결책 | 추천 | 생길 수 있는 문제 |" "| 번호 | 위치 | 조건 | 깨지는 것 | 확인 |" \
         "| Unit | Solutions | Recommendation | Possible problems |" "| No. | Location | Condition | What breaks | Check |" \
         "| 単位 | 解決策 | 推奨 | 起こりうる問題 |" "| 番号 | 場所 | 条件 | 壊れるもの | 確認 |"; do
  [[ "$(pt "$(printf '결론.\n\n%s\n|---|\n' "$x")")" == 1 ]] && c=$((c + 1)) || echo "      ✖ not caught: $x"
done
for x in $'| 단위 | 해결책 | 추천 |\n|---|---|---|\n| a | ①x | ① 이유 |' $'설명.\n```\n| 번호 | 위치 | 조건 | 깨지는 것 | 확인 |\n```' \
         $'> | 단위 | 해결책 | 추천 | 생길 수 있는 문제 |' $'문제 표는 이제 쓰지 않는다 — 생길 수 있는 문제는 해결책이 막는다.'; do
  [[ "$(pt "$x")" == 0 ]] && c=$((c + 1)) || echo "      ✖ wrongly caught: $(head -c 50 <<<"$x")"
done
[[ $c -eq 10 ]] && ok "잡을 것 6(한 · 영 · 일 × 문제 칸 · 문제 표) · 잡지 않을 것 4(세 칸 단위 표 · 코드 블록 · 인용 · 줄글)" || fail "T23 판정 $c/10"

echo "── [T23] 문제 표 · 문제 칸 — 종료 훅이 같은 턴에 한 번 막는다 ──"
PTA=$'| 단위 | 해결책 | 추천 | 생길 수 있는 문제 |\n|---|---|---|---|\n| a | ①x | ① 이유 | P1 |'
R="$(fresh_turn t23)"
o="$(stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s\n\n%s\n\n%s' "결론." "$QUOTE" "$PTA" "끝났습니다.")" false)"
[[ "$(jq -r .decision <<<"$o" 2>/dev/null)" == block ]] && grep -q 'SCV 원칙' <<<"$o" && grep -q '해결책 안에서 막아' <<<"$o" \
  && ok "문제 칸이 있는 끝 메시지 — 막음, 이유에 해결책 안에서 막으라는 말" || fail "T23 막기: [$o]"
rm -f "$R/scv/journal/.help-warn"
o="$(stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s\n\n%s' "결론." "$QUOTE" "$PTA")" true)"
[[ -z "$o" ]] && grep -q '^\[SCV 가이드\] 직전 턴: \[SCV 원칙\]' "$R/scv/journal/.help-warn" 2>/dev/null && ok "이미 계속 중: 막지 않고 다음 턴 경고" || fail "T23 계속 중: [$o]"
o="$(stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s\n\n%s\n\n%s' "결론." "$QUOTE" "$PTA" "릴리스할까요?")" false)"
grep -q 'SCV 원칙' <<<"$o" && ! grep -q 'SCV 선택지' <<<"$o" && ok "문제 표와 글 질문이 함께 있으면 원칙 이유 하나만(한 번에 한 이유)" || fail "T23 한 이유: [$o]"
R="$(fresh_turn t23off)"; printf '{\n  "SCV_REWRITE_PRINCIPLE": "off"\n}\n' > "$R/scv/scv_settings.json"
o="$(stop_p "$R" "$WORK/profile-full.env" "$(printf '%s\n\n%s\n\n%s' "결론." "$QUOTE" "$PTA")" false)"
[[ -z "$o" ]] && ok "원칙 스위치 off — 판정 없음(이 기능 전과 같다)" || fail "T23 off: [$o]"
o="$(stop_p "$(new_repo t23nc)" "$WORK/profile-pick.env" "$(printf '%s\n\n%s' "결론." "$PTA")" false)"
[[ -z "$o" ]] && ok "원칙이 실리지 않는 호스트(요구 항목 데이터 없음) — 판정 없음" || fail "T23 no checklist: [$o]"

echo "── [T25] 프로젝트 스위치 · 끝 메시지 없음 · 실행부 인자 ──"
R="$(new_repo t25)"; printf '{\n  "SCV_CHOICE_GATE": "off"\n}\n' > "$R/scv/scv_settings.json"
o="$(hook_p "$R" "$WORK/profile-pick.env" "안녕")"; ! grep -q 'SCV choices' <<<"$o" && ok "SCV_CHOICE_GATE=off — 안내 줄 없음" || fail "T25 off 안내"
o="$(stop_p "$R" "$WORK/profile-pick.env" "$C_E" false)"; [[ -z "$o" ]] && ok "SCV_CHOICE_GATE=off — 글로 물어도 막지 않음" || fail "T25 off 판정: [$o]"
R="$(new_repo t25b)"; TR="$WORK/t25b.jsonl"; { jl_user "q"; jl_asst "$C_E"; } > "$TR"
o="$(cd "$R" && jq -cn --arg p "$TR" '{transcript_path:$p}' | SCV_CORE_ROOT="$CORE" SCV_HOST_PROFILE="$WORK/profile-pick.env" GIT_AUTHOR_NAME=t bash "$STOP_HOOK" 2>/dev/null)"
[[ -z "$o" ]] && ok "호스트가 끝 메시지를 주지 않으면 판정하지 않는다(원본의 앞선 글로 막지 않음)" || fail "T25 끝 메시지 없음: [$o]"
rc="$(printf 'x?' | SCV_HOST_PROFILE="$WORK/profile-pick.env" perl -e 'alarm 5; exec @ARGV' bash "$GATE" stop --active >/dev/null 2>&1; echo $?)"
[[ "$rc" == 0 ]] && ok "값 없는 --active 에도 끝난다" || fail "T25 --active 값 없음 rc=$rc"

echo "── [T26] 긴 턴 — 종료 훅이 이번 턴만 작게 잘라 빨리 끝난다 ──"
R="$(fresh_turn t26)"; TR="$WORK/t26.jsonl"
{ jl_user "로그인 고쳐"; jl_asst "$(printf '결론.\n\n%s' "$QUOTE")"
  for i in $(seq 1 1500); do jl_tool; jl_asst "진행 메모 $i — 이번 단계에서 확인한 것을 적는다. 다음 단계로 넘어간다."; done; } > "$TR"
t0=$(date +%s); o="$(stop_tr "$R" "$WORK/profile-full.env" "$TR" "끝났습니다.")"; t1=$(date +%s)
[[ -z "$o" ]] && ok "$(wc -l < "$TR" | tr -d ' ')줄 · 답 1501개 턴: 앞선 인용을 찾고 막지 않음 ($((t1 - t0))s)" || fail "T26: [$o]"
(( t1 - t0 <= 30 )) && ok "30초 안에 끝난다 (검토 전 방식은 같은 꼴에서 수십 초)" || fail "T26 느림: $((t1 - t0))s"

echo; echo "test-choice-questions: pass=$PASS fail=$FAIL"
(( FAIL == 0 ))
