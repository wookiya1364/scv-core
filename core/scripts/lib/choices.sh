#!/usr/bin/env bash
# lib/choices.sh — 고르게 할 때 규칙(contracts/choices.md)의 순수부. 효과(호스트 설정 읽기 · 경고 쓰기)는 scripts/choice-gate.sh.
#
#   scv_choice_line <도구 이름>                → 매 턴 안내 한 줄 | 빈 값(도구가 없으면)
#   scv_answer_body <답>                       → 코드 블록과 인용 줄(다시 쓴 요청 등)을 뺀 본문
#   scv_asks_in_text <본문>                    → 1(글로 묻거나 번호로 고르게 하면서 끝남) | 0
#   scv_choice_gate <묻나> <도구 이름> <계속 중> → ok | block | warn
#   scv_choice_reason <도구 이름>              → 막는 이유 한 줄
#
# 꺾쇠 글자는 쓰지 않는다 — 순수성 검사가 리다이렉션으로 본다(인용 표시는 \x3e 로 만든다).

# @pure
# <도구 이름> → 매 턴 안내 한 줄. 도구가 없으면 아무것도 내지 않는다(이 기능 전과 같은 출력).
scv_choice_line() {
  local tool="${1:-}"
  [[ -n "$tool" ]] || return 0
  # 매 턴 실리는 줄 — 래퍼(요구 항목 블록 약 1.5KB)와 함께 매 턴 스택 상한(test-help-budget T12, 12,000B) 안. 요지만, 전문은 규칙 문서.
  printf '%s\n' "[SCV choices] Ask the user's decisions with $tool, never in text: recommended option first; each option says how it avoids its own problems; over 4 questions, consecutive calls; over 4 options, two steps; names, suggested values; cancelled, stop. A turn that ends asking in text is blocked (contracts/choices.md)."
}

# @pure
# <답> → 코드 블록(``` 울타리 안)과 인용 줄을 뺀 본문. 인용 속 물음표(다시 쓴 요청 등)는 질문이 아니다.
scv_answer_body() {
  local text="${1:-}" line t fence=0 q=$'\x3e' out=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    t="${line#"${line%%[![:space:]]*}"}"
    if [[ "$t" == '```'* ]]; then fence=$(( 1 - fence )); continue; fi
    (( fence )) && continue
    [[ "${t:0:1}" == "$q" ]] && continue
    out+="$line"$'\n'
  done <<< "$text"
  printf '%s' "$out"
}

# @pure
# <본문> → 1 | 0. 끝 문단이 사용자에게 고르게 하거나 묻는가:
#   (a) 번호로 답하라는 말 · "다 추천대로" (한국어 · 영어 · 일본어)
#   (b) 질문 · 추천 칸이 있는 결정 표
#   (c) 마지막 줄이 물음표로 끝남 — 끝의 괄호 덧붙임 "(추천: 예)" 와 꾸밈 글자는 걷어 내고 본다
#   (d) 끝 줄이 표의 행이고 표 안에 물음표로 끝나는 칸이 있음
# 본문 중간의 물음표와 평서문으로 끝나는 답은 묻는 것이 아니다.
scv_asks_in_text() {
  local body="${1:-}" line last="" para="" reset=0 t cue hit=0 nc=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "${line//[[:space:]]/}" ]]; then reset=1; continue; fi
    if (( reset )); then para=""; reset=0; fi
    para+="$line"$'\n'; last="$line"
  done <<< "$body"
  [[ -n "$last" ]] || { printf '0'; return 0; }
  shopt -q nocasematch && nc=1
  shopt -s nocasematch
  for cue in "번호로 답" "번호만 알려" "번호로 골라" "번호로 알려" "다 추천대로" "추천대로'라고" "추천대로라고" \
             "answer by number" "reply with the number" "answer with the number" "reply with a number" "pick a number" \
             "番号で答" "番号でお答" "番号だけ"; do
    [[ "$para" == *"$cue"* ]] && { hit=1; break; }
  done
  if (( ! hit )); then
    while IFS= read -r line || [[ -n "$line" ]]; do
      t="${line#"${line%%[![:space:]]*}"}"
      [[ "${t:0:1}" == "|" ]] || continue
      if [[ "$t" == *"질문"* || "$t" == *"question"* || "$t" == *"質問"* ]] \
         && [[ "$t" == *"추천"* || "$t" == *"recommend"* || "$t" == *"推奨"* ]]; then hit=1; break; fi
    done <<< "$para"
  fi
  (( nc )) || shopt -u nocasematch
  if (( ! hit )); then
    t="${last%"${last##*[![:space:]]}"}"
    if [[ "${t#"${t%%[![:space:]]*}"}" == "|"* ]]; then
      [[ "$para" == *"?|"* || "$para" == *"? |"* || "$para" == *"？|"* || "$para" == *"？ |"* ]] && hit=1
    else
      if [[ "$t" == *")" && "$t" == *"("* ]]; then t="${t%(*}"; t="${t%"${t##*[![:space:]]}"}"; fi
      while [[ -n "$t" ]]; do
        case "$t" in
          *'**'|*'__') t="${t%??}" ;;
          *'*'|*'_'|*'"'|*"'"|*'`'|*')') t="${t%?}" ;;
          *'」'|*'』'|*'”'|*'’') t="${t%?}" ;;
          *) break ;;
        esac
        t="${t%"${t##*[![:space:]]}"}"
      done
      case "$t" in *'?'|*'？') hit=1 ;; esac
    fi
  fi
  printf '%s' "$hit"
}

# @pure
# <묻나 0|1> <도구 이름> <이미 계속 중 0|1> → ok | block | warn. 도구가 없으면 늘 ok(이 기능 전과 같다).
# 이미 계속 중이면 막지 않는다 — 같은 턴 한 번, 다음 턴 경고로 넘긴다.
scv_choice_gate() {
  local asks="${1:-0}" tool="${2:-}" active="${3:-0}"
  [[ -n "$tool" && "$asks" == "1" ]] || { printf 'ok'; return 0; }
  if [[ "$active" == "1" ]]; then printf 'warn'; else printf 'block'; fi
}

# @pure
# <도구 이름> → 막는 이유 한 줄 — 모델이 이것만 읽고 바로 다시 물을 수 있게 규칙 요지를 담는다.
scv_choice_reason() {
  local tool="${1:-the choice tool}"
  printf '%s' "[SCV 선택지] 사용자에게 고르게 하거나 묻는 글로 턴을 끝냈다 — $tool 로 다시 물어라: 결정 하나에 질문 하나, 첫 보기가 추천, 보기마다 그 보기가 부를 문제를 막는 방법, 질문이 4개를 넘으면 중요한 것부터 나눠 연달아, 보기가 4개를 넘으면 두 단계로. 고를 것이 아니면 질문 없이 끝내라(contracts/choices.md)."
}
