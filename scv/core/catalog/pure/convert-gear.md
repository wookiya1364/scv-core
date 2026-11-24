# 변환/gear — 한 표기를 다른 표기로 바꾼다 — 경로 · 날짜 · 단위 · 인코딩

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 2개.

### scv_gear_lit_decode
- 역할: 예시에 적은 글 표기를 실제 글로 푼다 — $'…'(\n \t \\ \' \") 와 "…"(\" \\ \$) 두 모양, 그 밖은 그대로
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"\$'a\\tb\\nc'" → $'a\tb\nc'`
- 예: `'"가 나"' → "가 나"`
- 예: `'plain' → "plain"`

### scv_gear_teeth_parse
- 역할: 톱니 사전 글(### 이름 · - 역할 · - 표시 · - 값)을 사전 줄들로 바꾼다 — 줄 끝 CR 과 값 앞뒤 빈칸은 뗀다. 표시가 없으면 "?"(그런 톱니는 돌리지 않는다), 값이 없으면 "*"
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'### up\n- 역할: 대문자로\n- 표시: pure\n- 값: text → text\n- 예: "a" → "A"' → $'up\ttooth\tpure\ttext\ttext\t대문자로\t'`
- 예: `$'# 톱니 사전\n\n### a\n- 역할: 하나\n\n### b \r\n- 표시:  effect \r\n- 역할: 둘\r\n- 값: x  →  y ' → $'a\ttooth\t?\t*\t*\t하나\t\nb\ttooth\teffect\tx\ty\t둘\t'`
- 예: `"" → ""`
