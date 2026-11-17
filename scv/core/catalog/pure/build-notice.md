# 조립/notice — 조각을 받아 정해진 모양의 글을 만든다 — 줄 · 표 · 메시지

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 2개.

### scv_correction_notice
- 역할: 고쳐 달라는 말인지 · 직전 턴이 끝났는지 · 직전 턴이 바꾼 파일 수로, 검사로 남기기를 묻게 할 안내 한 줄을 낸다
- 위치: scripts/lib/correction-check.sh · @pure · sh
- 예: `1 1 3 korean → "[SCV 정정] 직전 턴의 일을 고쳐 달라는 말로 보인다 — 고친 뒤, 같은 실수를 다시 막을 검사(시험 · 린트 · 훅)로 남길지 선택 창으로 물어라(보기: 검사로 남기기 · 넘어가기). 고르기 전에는 검사 파일을 만들지 않는다."`
- 예: `1 1 3 english → "[SCV correction] This reads as a correction of the last turn's work — after fixing it, ask with the choice tool whether to keep it as a check (test · lint · hook) that stops the same mistake (options: keep as a check · skip). Create no check file before the answer."`
- 예: `1 0 3 korean → ""`
- 예: `1 1 0 korean → ""`
- 예: `0 1 3 korean → ""`

### scv_workaround_note
- 역할: 고른 임시방편 주석 줄들을 계획 끝 알림 글로 만든다 — 막지 않는다는 것과 할 일을 함께 적는다
- 위치: scripts/lib/comment-flag.sh · @pure · sh
- 예: `$'a.sh\t2\t# TODO: 나중에 제거' → $'새 임시방편 주석 1개 (막지 않음 — 검사로 옮기거나 WRAPUP 의 남은 빚으로 적어라):\n  a.sh:2  # TODO: 나중에 제거'`
- 예: `"" → ""`
