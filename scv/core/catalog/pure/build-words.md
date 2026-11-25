# 조립/words — 조각을 받아 정해진 모양의 글을 만든다 — 줄 · 표 · 메시지

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 3개.

### scv_words_note
- 역할: 직전 답에서 찾은 피할 말들로 다음 턴에 실을 한 줄을 만든다 — 찾은 것이 없으면 빈 값
- 위치: scripts/lib/words.sh · @pure · sh
- 예: `"잰 → 측정하다" → "[SCV 낱말] 직전 답에 피할 말이 있었다: 잰 → 측정하다 — 같은 뜻으로 쓴 것이면 이번 답부터 바꿔 말하라(직전 답은 다시 쓰지 않는다)."`
- 예: `$'잰 → 측정하다\n유저 → 사용자' → "[SCV 낱말] 직전 답에 피할 말이 있었다: 잰 → 측정하다, 유저 → 사용자 — 같은 뜻으로 쓴 것이면 이번 답부터 바꿔 말하라(직전 답은 다시 쓰지 않는다)."`
- 예: `$'a → 1\nb → 2\nc → 3' 2 → "[SCV 낱말] 직전 답에 피할 말이 있었다: a → 1, b → 2 외 1개 — 같은 뜻으로 쓴 것이면 이번 답부터 바꿔 말하라(직전 답은 다시 쓰지 않는다)."`
- 예: `"" → ""`

### scv_words_text
- 역할: 대화 첫머리에 실을 낱말 안내 묶음을 만든다 — 머리 한 줄과 항목마다 한 줄("피할 말(꼴들) → 쓸 말"). 항목이 없으면 빈 값
- 위치: scripts/lib/words.sh · @pure · sh
- 예: `$'재다\t측정하다\t잰, 재서\t수치 얘기' korean → $'[SCV 낱말] 아래 왼쪽 말은 쓰지 않는다 — 그 활용 · 같은 계열의 말도 쓰지 않는다(괄호 안의 꼴은 예일 뿐 전부가 아니다). 오른쪽 말을 문장에 맞게 활용해 쓴다. 사용자가 읽는 모든 글(답 · 중간 보고 · 요약)에 적용하고, 코드 · 파일 이름 · 인용한 사용자 글 · 명령에는 적용하지 않는다.\n- 재다(잰, 재서) → 측정하다 — 수치 얘기'`
- 예: `$'utilize\tuse\t\t' english → $'[SCV words] Do not use a word on the left, or any inflection or same-family form of it (the forms in brackets are examples, not the whole list) — say the word on the right instead, conjugated to fit the sentence. This applies to everything the user reads (answers, progress notes, summaries), not to code, file names, quoted user text or commands.\n- utilize → use'`
- 예: `"" korean → ""`

### scv_words_upsert
- 역할: 항목 줄들에 항목 하나를 넣는다 — 같은 피할 말이 있으면 그 자리에서 갈아 끼우고, 꼴 · 메모를 주지 않았으면 있던 것을 지킨다
- 위치: scripts/lib/words.sh · @pure · sh
- 예: `"" 재다 측정하다 "잰, 재서" 1 "" 0 → $'재다\t측정하다\t잰, 재서\t'`
- 예: `$'재다\t측정하다\t잰, 재서\t수치 얘기\n유저\t사용자\t\t' 재다 계측하다 "" 0 "" 0 → $'재다\t계측하다\t잰, 재서\t수치 얘기\n유저\t사용자\t\t'`
- 예: `$'재다\t측정하다\t잰, 재서\t수치 얘기' 재다 측정하다 "쟀다" 1 "" 1 → $'재다\t측정하다\t쟀다\t'`
- 예: `$'재다\t측정하다\t\t' 유저 사용자 "" 0 "" 0 → $'재다\t측정하다\t\t\n유저\t사용자\t\t'`
