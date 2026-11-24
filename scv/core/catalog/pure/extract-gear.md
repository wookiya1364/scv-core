# 꺼내기/gear — 글 · JSON · 표에서 값이나 필드를 뽑는다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 7개.

### scv_gear_body
- 역할: 기어 글에서 맨 위 줄들(칸: 값)과 그 뒤 빈 줄을 뺀 본문을 낸다 — 판단 단계에서 모델이 읽는 글
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'flow: a | @\ndoes: x\n\n# 글\n요약한다' → $'# 글\n요약한다'`
- 예: `$'flow: a | b\n' → ""`
- 예: `"그냥 글" → "그냥 글"`

### scv_gear_confirm_token
- 역할: 질문 글에서 기어 확인 표를 꺼낸다 — "[기어 확인 <16진 8자>:<단계 번호>]" 모양일 때 "표:단계", 아니면 빈 값
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"보낼까요? [기어 확인 ab12cd34:2]" → "ab12cd34:2"`
- 예: `"보낼까요? [기어 확인 ab12cd34]" → ""`
- 예: `"보낼까요?" → ""`
- 예: `"[기어 확인 ../x:1]" → ""`

### scv_gear_example_split
- 역할: 예시 한 줄("<입력 표기> → <출력 표기>")을 입력 표기와 출력 표기 두 줄로 나눈다 — 모양이 아니면 빈 값
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"\"a b\" → \"A B\"" → $'"a b"\n"A B"'`
- 예: `"\$'x → y' → \"z\"" → $'$\'x → y\'\n"z"'`
- 예: `"화살표 없음" → ""`

### scv_gear_flow_parse
- 역할: flow 줄의 값을 단계 이름 줄들로 나눈다 — | 로 나누고 앞뒤 빈칸을 뗀다. @ 는 이 기어의 글(판단 단계)
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"a | b | @ | c" → $'a\nb\n@\nc'`
- 예: `" a|b " → $'a\nb'`
- 예: `"" → ""`

### scv_gear_front_get
- 역할: 기어 글(GEAR.md)의 맨 위 줄들(칸: 값)에서 한 칸의 값을 꺼낸다 — 첫 빈 줄이나 칸 모양이 아닌 줄에서 멈춘다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'flow: a | @ | b\ndoes: 초안을 만든다\n\n# 글' "flow" → "a | @ | b"`
- 예: `$'flow: a | @ | b\ndoes: 초안을 만든다\n\n# 글' "does" → "초안을 만든다"`
- 예: `$'# 글\nflow: a' "flow" → ""`

### scv_gear_index_get
- 역할: 사전 글에서 기어 · 톱니 한 개의 한 칸을 꺼낸다 — 칸: kind · mark · in · out · does · words. 이름이나 칸이 없으면 빈 값
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'up\ttooth\tpure\ttext\tnumber\t대문자로\t낱말' "up" "kind" → "tooth"`
- 예: `$'up\ttooth\tpure\ttext\tnumber\t대문자로\t낱말' "up" "out" → "number"`
- 예: `$'up\ttooth\tpure\ttext\tnumber\t대문자로\t낱말' "upper" "kind" → ""`

### scv_gear_tooth_examples
- 역할: 톱니 사전 글에서 톱니 한 개의 예시 줄들을 꺼낸다 — "- 예:" 뒤의 글만, 한 줄에 하나(줄 끝 CR 과 앞뒤 빈칸은 뗀다)
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'### up\n- 예: "a" → "A"\n- 예: "" → ""\n### low\n- 예: "A" → "a"' "up" → $'"a" → "A"\n"" → ""'`
- 예: `$'### up \r\n- 예:  "a" → "A" \r' "up" → '"a" → "A"'`
- 예: `$'### up\n- 역할: x' "up" → ""`
