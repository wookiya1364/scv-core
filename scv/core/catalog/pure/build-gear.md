# 조립/gear — 조각을 받아 정해진 모양의 글을 만든다 — 줄 · 표 · 메시지

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 4개.

### scv_gear_confirm_text
- 역할: 밖으로 나가는 톱니 앞에서 낼 글을 만든다 — 확인 표(표:단계) · 단계 · 묻는 방법(질문 끝의 표와 두 보기) · 이어가는 명령 · 그 톱니가 돌릴 글
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"ab12cd34" "2/2 send — 보낸다" "git push" "gear.sh resume ab12cd34" "2" → $'GEAR_CONFIRM: ab12cd34\nGEAR_STEP: 2/2 send — 보낸다\n=== 밖으로 나가는 단계 ===\n사용자에게 선택 도구로 물어라 — 질문 글 끝에 [기어 확인 ab12cd34:2] 를 그대로 넣고, 보기는 "실행" 과 "실행하지 않음" 둘.\n"실행" 답이 온 뒤에만: gear.sh resume ab12cd34\n=== 이 단계가 돌릴 글 ===\ngit push'`

### scv_gear_handoff_text
- 역할: 판단 단계에서 모델에게 넘길 글을 만든다 — 이어가기 표 · 단계 · 그 기어의 글 · 앞 단계 결과 · 이어가는 명령
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"ab12cd34" "2/3 @sum — 요약" "글" "앞" "gear.sh resume ab12cd34" → $'GEAR_HANDOFF: ab12cd34\nGEAR_STEP: 2/3 @sum — 요약\n=== 이 단계의 글 ===\n글\n=== 앞 단계 결과 ===\n앞\n=== 이어가기 ===\n이 단계의 결과만 표준 입력으로 넘겨라: gear.sh resume ab12cd34'`

### scv_gear_index_build
- 역할: 사전 줄들을 이름 순(바이트 순)으로 늘어놓아 사전 글을 만든다 — 빈 줄은 뺀다
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `$'b\ttooth\tpure\t*\t*\t둘\t\na\ttooth\tpure\t*\t*\t하나\t' → $'a\ttooth\tpure\t*\t*\t하나\t\nb\ttooth\tpure\t*\t*\t둘\t'`
- 예: `"" → ""`

### scv_gear_tooth_entry
- 역할: 톱니 사전에 덧붙일 항목 글을 만든다 — 이름 · 역할 · 표시 · 값 · 예시(있으면)
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"up" "대문자로" "pure" "text" "text" "\"a\" → \"A\"" → $'### up\n- 역할: 대문자로\n- 표시: pure\n- 값: text → text\n- 예: "a" → "A"'`
- 예: `"log" "커밋을 모은다" "effect" "none" "subjects" "" → $'### log\n- 역할: 커밋을 모은다\n- 표시: effect\n- 값: none → subjects'`
