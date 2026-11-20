# 판정/ask — 입력을 보고 예/아니오나 판정 이름 하나를 낸다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 3개.

### scv_ask_mode
- 역할: 묻기 모드 설정 값을 all · ends 로 가른다 — ends(대소문자 무관)만 ends, 없거나 다른 값은 all(기본, 지금과 같음)
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `"ends" → "ends"`
- 예: `" ENDS " → "ends"`
- 예: `"" → "all"`
- 예: `"start" → "all"`

### scv_ask_mode_next
- 역할: 지금 묻기 모드와 명령 인자로 바꿀 모드를 고른다 — 인자가 ends · all 이면 그 값, 비었으면 뒤집기, 그 밖은 빈 값(잘못된 인자)
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `all "" → "ends"`
- 예: `ends "" → "all"`
- 예: `ends all → "all"`
- 예: `all ENDS → "ends"`
- 예: `all "maybe" → ""`

### scv_ask_policy
- 역할: 묻기 모드와 묻는 자리로 이 자리에서 물을지(ask) 추천대로 정할지(recommend)를 고른다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `all mid → "ask"`
- 예: `ends outline → "ask"`
- 예: `ends verify → "ask"`
- 예: `ends irreversible → "ask"`
- 예: `ends mid → "recommend"`
- 예: `ends first-run → "recommend"`
