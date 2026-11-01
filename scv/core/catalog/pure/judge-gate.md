# 판정/gate — 훅이 막을지 · 넘길지 · 다시 물을지를 정한다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 18개.

### scv_choice_gate
- 역할: 묻는지 · 도구 이름 · 이미 전달 여부로 ok | block | warn 중 하나를 정한다 (도구가 없으면 늘 ok)
- 위치: scripts/lib/choices.sh · @pure
- 예: `1 ChoiceTool 0 → $'block'`
- 예: `1 ChoiceTool 1 → $'warn'`
- 예: `1 "" 0 → "ok"`

### scv_choice_off_when
- 역할: "이름=값" 조건과 지금 그 이름의 환경 값이 같으면 1(선택지 도구가 없는 실행), 아니면 0 을 낸다
- 위치: scripts/lib/choices.sh · @pure
- 예: `HEADLESS=1 1 → "1"`
- 예: `HEADLESS=1 0 → "0"`
- 예: `"" 1 → "0"`

### scv_dreams_day_trigger
- 역할: 지난 드림 날짜와 오늘 날짜가 달라 드림을 띄울 때인지 1 또는 0 으로 낸다
- 위치: scripts/lib/dreams.sh · @pure
- 예: `"" 20261001 → '1'`
- 예: `20261001 20261001 → '0'`
- 예: `20260930 20261001 → '1'`

### scv_dreams_start_trigger
- 역할: 훅 입력의 source 값이 드림을 띄울 때(clear · compact)인지 1 또는 0 으로 낸다
- 위치: scripts/lib/dreams.sh · @pure
- 예: `clear → '1'`
- 예: `startup → '0'`

### scv_drift_decide
- 역할: 메아리 판정 · 린트 위반 · 스위치로 규약을 다시 실을지(1|0)와 다음 턴 경고 줄을 정한다
- 위치: scripts/lib/help-state.sh · @pure
- 예: `missing "" on on → $'1\x1f[SCV 규약 지문] 직전 턴 기록에 이 세션의 규약 지문이 없다 — 규약이 컨텍스트에서 빠진 것으로 보고 이번 턴에 다시 싣는다.'`
- 예: `ok "" on on → $'0\x1f'`

### scv_gates_delivered
- 역할: 이 검사가 이 세션 · 이 턴에 이미 전달됐는지 1 또는 0 으로 판정한다(깨진 기록은 1)
- 위치: scripts/lib/stop-gates.sh · @pure
- 예: `g1 1 s t $'s\x1ft\x1fg1' → "1"`
- 예: `g1 1 s t $'s\x1ft\x1fg2' → "0"`
- 예: `g1 0 s t '' → "0"`

### scv_gates_drop
- 역할: 첫 멈춤에서 이 세션의 지난 기록이나 깨진 기록을 지워야 하면 1, 아니면 0 을 낸다
- 위치: scripts/lib/stop-gates.sh · @pure
- 예: `s $'s\x1ft\x1fg1' 0 → "1"`
- 예: `s $'o\x1ft\x1fg1' 0 → "0"`
- 예: `s $'s\x1ft\x1fg1' 1 → "0"`

### scv_mp_decision
- 역할: 색인 행 유무 · 읽음 기록 · 지금 지문 · 모델 id 로 원문을 읽어야 하는지(load · loaded · none) 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `1 $'n1\x1fm' n1 m → "loaded"`
- 예: `1 "" n1 m → "load"`
- 예: `0 "" n1 m → "none"`

### scv_mp_guide_decide
- 역할: 읽은 모델 집합에 이 모델이 있으면 loaded, 없으면 load 로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `"m-1 m-2" m-1 → "loaded"`
- 예: `"m-1" m-2 → "load"`
- 예: `N m-1 → ""`

### scv_mp_guide_from_events
- 역할: 사건 줄들을 접어 이 모델 원문을 읽었는지(loaded · load) 한 번에 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `$'M\x1fbash model-prompting.sh mark --model m-1' m-1 → "loaded"`
- 예: `N m-1 → ""`

### scv_mp_principle_gate
- 역할: 문제 표 · 스위치 · 이미 전달 여부로 종료를 허용할지(ok · block · warn) 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `1 on 0 → "block"`
- 예: `1 on 1 → "warn"`
- 예: `0 on 0 → "ok"`

### scv_mp_register_problems
- 역할: 병합 목록과 제출 텍스트를 견줘 빠진 · 잘못된 항목 줄들을 낸다(통과면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `$'a\tA' $'a\tmsg\tv\nrewrite\t-\tr' → ""`
- 예: `$'a\tA' '' → $'missing a\nmissing rewrite\n'`

### scv_mp_rewrite_recorded
- 역할: 대화 블록에 "다시 쓴 요청" 단락이 있는지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `$'a\n**Rewritten request**: x' → "1"`
- 예: `"없음" → "0"`

### scv_mp_scope_forbid
- 역할: 범위 칸이 변경을 막는 첫머리면 그 문구를, 아니면 빈 값을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `"읽기 전용 — 코드는 안 건드림" → "읽기 전용"`
- 예: `"파일은 바꾸지 않고 새 문서만" → ""`

### scv_mp_stop_gate
- 역할: 등록 · 보임 · 이미 전달 · 맨 위 한 줄로 종료를 허용할지(ok · block · warn) 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `1 1 0 1 → "ok"`
- 예: `0 "" 0 "" → "block"`
- 예: `0 "" 1 "" → "warn"`

### scv_mp_turn_verdict
- 역할: 결정 · 읽음 · 기록 · 인용 여부로 경고 판정(unread · unshown)을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `load 0 0 "" → $'unread\n'`
- 예: `loaded 1 1 0 → $'unshown\n'`
- 예: `none 0 0 0 → ""`

### scv_mp_write_gate
- 역할: 이번 턴 등록 상태로 파일 쓰기를 허용할지(ok · unregistered · answered · forbidden) 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `tok1 "" "" 0 0 → "unregistered"`
- 예: `tok1 $'tok1\x1fm\x1f3' '' 1 1 → "forbidden"`
- 예: `"" "" "" 0 0 → "ok"`

### scv_template_decide
- 역할: 도장 · 꾸러미의 지문과 버전을 보고 템플릿을 어떻게 할지 한 단어(skip:backward 등)로 판정한다
- 위치: scripts/lib/template-digest.sh · @pure
- 예: `abc abc 1.0.0 1.0.0 → "skip:same"`
- 예: `abc def 1.1.0 1.0.0 → "skip:backward"`
- 예: `abc def 1.1.0 1.2.0 → "refresh"`
