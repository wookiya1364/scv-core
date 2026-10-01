#!/usr/bin/env bash
# lib/choices.sh — 고르게 할 때 규칙(contracts/choices.md)의 순수부. 효과(호스트 설정 읽기 · 경고 쓰기)는 scripts/choice-gate.sh.
#
#   scv_choice_line <도구 이름>                → 매 턴 안내 한 줄 | 빈 값(도구가 없으면)
#   scv_answer_body <답>                       → 코드 블록과 인용 줄(다시 쓴 요청 등)을 뺀 본문
#   scv_asks_in_text <본문>                    → 1(글로 묻거나 번호로 고르게 하면서 끝남) | 0
#   scv_choice_gate <묻나> <도구 이름> <계속 중> → ok | block | warn
#   scv_choice_reason <도구 이름>              → 막는 이유 한 줄
#   scv_choice_off_when <조건 이름=값> <지금 값> → 1(이 실행에는 선택지 도구가 없다) | 0
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
# <본문> → 1 | 0. 답이 사용자에게 고르게 하거나 묻는 글로 끝나는가:
#   (a) 요청하는 말(끝 두 문단에서) — 번호로 답해 달라 · 골라 / 정해 / 선택해 달라 · "'다 추천대로'라고"(한 · 영 · 일). 요청형만 본다 —
#       "다 추천대로 반영했습니다" 같은 평서문은 잡지 않는다.
#   (b) 끝 문단이 결정 표 — 머리에 질문 · 추천 칸이 있고, 고른 것 · 답 · 결과 칸은 없다(되짚는 표는 정보다).
#   (c) 실제 끝 줄이 물음표로 끝남 — 끝에 붙은 보기 목록(1. · - · ①)은 건너뛰고 그 앞 줄을 본다. 끝의 괄호 덧붙임
#       "(추천: 예)" · 굵게 · 따옴표 · 이모티콘은 걷어 내고 본다. 걷는 것은 글자 그대로의 꼬리라 로캘과 무관하다.
#       표의 행으로 끝나는 답은 (c) 를 보지 않는다 — 표 안의 물음표는 정보다.
#   (d) 끝 문단(표 줄 제외)의 마지막 '문장 끝 물음표' 뒤에 분명한 추천("추천은" · "(추천" · "I recommend" …)이나 요청("알려
#       주세요" · "let me know" …)이 온다 — "…할까요? 추천은 …입니다." · "…맞나요? 아니면 알려 주세요." 뒤가 공백 · 줄 끝 · 괄호 ·
#       굵게가 아닌 물음표(주소의 ?id=3 · 옮겨 적은 질문의 ?')와 앞이 물음표 · 공백 · 백틱인 것(연산자 ??)은 건너뛰고 그 앞을 본다.
#       전각 물음표(？)는 늘 문장 끝이다. 물음표 바로 뒤에 "네," · "Yes —" 같은 답이 오면 혼잣말 질문이라 묻는 것이 아니다.
#       끝 4000글자만 본다(큰 글에서 패턴 자르기가 제곱으로 느려진다).
#   (a) 와 (d) 는 실제 답 모음(로컬 원본 230턴)에서 놓친 모양으로 넓혔다 — 질문 뒤 추천 문장, "답해 주시면 됩니다",
#       "할지 알려 주세요", "라고 해 주세요", 한 줄 보기 목록 "[1] … / [2] …" (2026-10-01 실측).
# 본문 중간의 물음표, 평서문으로 끝나는 답, 정보 표, "필요하면 말씀해 주세요" · "언제든지 알려 주세요" 같은 제안 · 맺음 인사는
# 묻는 것이 아니다. 빈 줄(문단 경계)은 ASCII 공백만으로 이뤄진 줄이다 — 로캘에 따라 문단이 달라지지 않게.
scv_asks_in_text() {
  local body="${1:-}" line t cue hit=0 nc=0 n=0 i last="" para="" ppara="" reset=0 prev pre ptext="" after="" q=0 c1 a1 a2 f1 f2 k np=0
  local -a PL=()
  local item_re='^([-*+]|[0-9]+[.)]|\([0-9]+\)|\[[0-9]+\]|①|②|③|④|⑤|⑥|⑦|⑧|⑨|⑩)[[:space:]]'
  local -a L=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" != *[!$' \t\r\v\f']* ]]; then reset=1; continue; fi
    if (( reset )); then ppara="$para"; para=""; reset=0; fi
    para+="$line"$'\n'
    L[n]="$line"; n=$((n + 1))
  done <<< "$body"
  (( n )) || { printf '0'; return 0; }
  i=$((n - 1))
  while (( i > 0 )); do
    t="${L[i]#"${L[i]%%[![:space:]]*}"}"
    [[ "$t" =~ $item_re ]] || break
    i=$((i - 1))
  done
  last="${L[i]}"
  shopt -q nocasematch && nc=1
  shopt -s nocasematch
  for cue in "번호로 답해 주세요" "번호로 답해주세요" "번호로 답해 줘" "번호만 알려 주세요" "번호만 알려주세요" \
             "번호로 알려 주세요" "번호로 알려주세요" "추천대로'라고" "추천대로라고" "골라 주세요" "골라주세요" \
             "정해 주세요" "정해주세요" "선택해 주세요" "선택해주세요" "결정해 주세요" "결정해주세요" \
             "answer by number" "reply with the number" "answer with the number" "reply with a number" \
             "let me know which" "which one would you" "which would you prefer" "which do you prefer" \
             "please choose" "please pick" "please select" "please decide" \
             "番号でお答え" "番号で答えて" "番号でご回答" "選んでください" "決めてください" "お選びください" \
             "답해 주시면" "답해주시면" "답해 주세요" "답해주세요" "라고 해 주세요" "라고 해주세요" \
             "지 알려 주세요" "지 알려주세요" "지 알려 주시면" "지 알려주시면" "지 말씀해 주세요" "지 말씀해주세요" \
             "let me know whether" "tell me which" "tell me whether" "か教えてください" "とお答えください"; do
    if [[ "$para" == *"$cue"* || "$ppara" == *"$cue"* || "$last" == *"$cue"* ]]; then
      # "언제든지 알려 주세요" · "얼마든지 말씀해 주세요" 는 맺음 인사다 — "…할지 · …인지 알려 주세요" 만 묻는 말이다
      if [[ "$cue" == "지 "* ]] && [[ "$para" == *"든$cue"* || "$ppara" == *"든$cue"* || "$last" == *"든$cue"* ]]; then continue; fi
      hit=1; break
    fi
  done
  if (( ! hit )); then
    while IFS= read -r line || [[ -n "$line" ]]; do
      t="${line#"${line%%[![:space:]]*}"}"
      [[ "${t:0:1}" == "|" ]] || continue
      if [[ "$t" == *"질문"* || "$t" == *"question"* || "$t" == *"質問"* ]] \
         && [[ "$t" == *"추천"* || "$t" == *"recommend"* || "$t" == *"推奨"* ]] \
         && [[ "$t" != *"고른"* && "$t" != *"답"* && "$t" != *"결과"* && "$t" != *"chosen"* && "$t" != *"answer"* \
               && "$t" != *"result"* && "$t" != *"選んだ"* && "$t" != *"結果"* ]]; then hit=1; break; fi
    done <<< "$para"
  fi
  (( nc )) || shopt -u nocasematch
  if (( ! hit )); then
    t="${last#"${last%%[![:space:]]*}"}"
    if [[ "${t:0:1}" != "|" ]]; then
      prev=""
      while [[ "$t" != "$prev" ]]; do
        prev="$t"
        t="${t%"${t##*[![:space:]]}"}"
        case "$t" in
          *':-)') t="${t%???}" ;;
          *'**'|*'__'|*':)'|*';)'|*'^^') t="${t%??}" ;;
          *'*'|*'_'|*'"'|*"'"|*'`'|*'~'|*'!'|*'.') t="${t%?}" ;;
          *'ㅎㅎ') t="${t%'ㅎㅎ'}" ;;
          *'ㅋㅋ') t="${t%'ㅋㅋ'}" ;;
          *'」') t="${t%'」'}" ;;
          *'』') t="${t%'』'}" ;;
          *'”') t="${t%'”'}" ;;
          *'’') t="${t%'’'}" ;;
          *'🙂') t="${t%'🙂'}" ;;
          *'😊') t="${t%'😊'}" ;;
          *'😀') t="${t%'😀'}" ;;
          *'🙏') t="${t%'🙏'}" ;;
          *'👍') t="${t%'👍'}" ;;
          *')')
            if [[ "$t" == *"("* ]]; then
              pre="${t%(*}"
              if [[ "$pre" == *[![:space:]]* ]]; then t="$pre"; else t="${t#(}"; t="${t%)}"; fi
            fi ;;
        esac
      done
      case "$t" in *'?'|*'？') hit=1 ;; esac
    fi
  fi
  if (( ! hit )); then
    while IFS= read -r line || [[ -n "$line" ]]; do
      t="${line#"${line%%[![:space:]]*}"}"
      [[ "${t:0:1}" == "|" ]] && continue
      PL[np]="$t"; np=$((np + 1))
    done <<< "$para"
    # 끝 40줄만 — 질문은 문단 끝 가까이 있고, ##*? · %?* 는 큰 글에서 제곱으로 느려진다(3.2 에서 64KB 13초). 줄 수로 자르면
    # 로캘과 무관하다. 한 줄이 아주 길 때만 글자 수로 한 번 더 자른다.
    k=0; (( np > 40 )) && k=$((np - 40))
    for (( ; k < np; k++ )); do ptext+="${PL[k]}"$'\n'; done
    (( ${#ptext} > 4000 )) && ptext="${ptext: -4000}"
    k=0
    while (( k < 20 )); do
      k=$((k + 1)); f1=0; f2=0; a1=""; a2=""
      [[ "$ptext" == *'?'* ]] && { a1="${ptext##*\?}"; f1=1; }
      [[ "$ptext" == *'？'* ]] && { a2="${ptext##*'？'}"; f2=1; }
      (( f1 || f2 )) || break
      if (( f2 )) && { (( ! f1 )) || (( ${#a2} <= ${#a1} )); }; then
        after="$a2"; ptext="${ptext%'？'*}"; c1="ok"
      else
        after="$a1"; ptext="${ptext%\?*}"; c1="${after:0:1}"
        case "${ptext: -1}" in '?'|' '|$'\t'|'`'|'') c1="x" ;; esac
        if [[ "$c1" != "x" ]]; then
          case "$c1" in ''|' '|$'\t'|$'\n'|')'|'('|'*'|'_') c1="ok" ;; *) if [[ "$after" == '　'* ]]; then c1="ok"; else c1="x"; fi ;; esac
        fi
      fi
      [[ "$c1" == "ok" ]] || continue
      q=1; break
    done
    if (( q )); then
      nc=0; shopt -q nocasematch && nc=1
      shopt -s nocasematch
      t="${after#"${after%%[![:space:]]*}"}"
      for cue in "네," "네." "네!" "네 —" "네—" "예," "예." "예!" "예 —" "예—" "아니요" "아니오" "아뇨" \
                 "Yes," "Yes." "Yes!" "Yes —" "Yes—" "Yes " "No," "No." "No!" "No —" "No—" "はい" "いいえ"; do
        [[ "$t" == "$cue"* ]] && { q=0; break; }
      done
      if (( q )); then
        for cue in "추천은" "추천:" "추천 :" "(추천" "（추천" "추천합니다" "를 추천" "을 추천" "제 추천" \
                   "i recommend" "my recommendation" "(recommended" "recommended:" "recommendation:" \
                   "おすすめは" "おすすめします" "推奨は" "(推奨" "（推奨" "推奨します" \
                   "알려 주세요" "알려주세요" "말씀해 주세요" "말씀해주세요" "답해 주세요" "답해주세요" \
                   "let me know" "tell me" "教えてください" "お知らせください"; do
          [[ "$after" == *"$cue"* ]] && { hit=1; break; }
        done
      fi
      (( nc )) || shopt -u nocasematch
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

# @pure
# <조건 "이름=값"> <지금 그 이름의 환경 값> → 1 | 0. 호스트가 선택지 도구를 빼는 실행(사람이 답할 수 없는 헤드리스 등)을
# 호스트 설정의 조건으로 알아본다 — 조건이 비었거나 모양이 틀리면 0(지금처럼 도구가 있다고 본다).
scv_choice_off_when() {
  local spec="${1:-}" now="${2:-}" name want
  [[ "$spec" == *=* ]] || { printf '0'; return 0; }
  name="${spec%%=*}"; want="${spec#*=}"
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ && -n "$want" ]] || { printf '0'; return 0; }
  [[ "$now" == "$want" ]] && printf '1' || printf '0'
}
