# 다듬기 — 글자를 정리한다 — 공백 · 대소문자 · 이스케이프 · 자르기

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 17개.

### record_kind_normalize
- 역할: 기록 종류 이름의 앞뒤 공백을 떼고 소문자로 맞춘다 — 모르는 종류는 빈 값
- 위치: scripts/lib/record-index.sh · @pure · sh
- 예: `' Decision ' → "decision"`
- 예: `plan → "plan"`
- 예: `nope → ""`

### scv_answer_body
- 역할: 답에서 코드 블록(``` 울타리 안)과 인용 줄을 빼고 본문만 남긴다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `$'a?\n> quoted?\n```\ncode?\n```\nb\n' → $'a?\nb'`

### scv_as_excerpt
- 역할: 아주 긴 줄에서 낱말이 맞은 자리 앞뒤만 남긴 대목을 낸다(짧으면 그대로)
- 위치: scripts/lib/archive-search.sh · @deterministic · sh
- 예: `'short line' short 100 → "short line"`
- 예: `'aaaaaaaaaaaaaaaaaaaaTARGETbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' TARGET 20 → "…aaaaaaTARGETbbbbbbbb…"`

### scv_dreams_esc
- 역할: 글의 & · 꺾쇠 · 따옴표 · « » 를 HTML 에 넣을 수 있게 이스케이프한다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `"a & b" → 'a &amp; b'`
- 예: `"x«y»" → 'x&laquo;y&raquo;'`

### scv_dreams_mask
- 역할: 글을 한 줄로 줄이고 경로 · 메일 · id · 열쇠 값을 가려 정해진 글자 수까지 자른다
- 위치: scripts/lib/dreams.sh · @deterministic · sh
- 예: `"mail a@b.com token=abc123 /opt/x/y" → 'mail [메일] token=[REDACTED] [경로]'`
- 예: `"abcdefghij" 5 → 'abcde…'`

### scv_force_trim_diagnosis
- 역할: 표준입력 점검 출력에서 진단부터 끝까지만 남긴다(표지를 못 찾으면 전체 그대로)
- 위치: scripts/lib/force-help.sh · @pure · sh
- 예: `<<< $'no marker here' → "no marker here"`
- 예: `<<< $'intro\nCurrent project diagnosis\nstate ok\nLearn more\nlong text' → $'Current project diagnosis\nstate ok'`

### scv_lang_drop_machine
- 역할: 사람이 쓰지 않은 기계 글 블록(작업 완료 알림 · 시스템 안내 · 명령 기록 · 이벤트)을 지운다 — 언어 판정이 사람 글만 보게
- 위치: scripts/lib/lang-enforce.sh · @pure · sh
- 예: `"<task-notification><summary>Background command completed</summary></task-notification>" → ""`
- 예: `"<system-reminder>## You are a session started from another session</system-reminder>잡몹 고치기" → "잡몹 고치기"`
- 예: `"영어로 답해 줘" → "영어로 답해 줘"`

### scv_lint_strip_quoted
- 역할: 글에서 따옴표 · 괄호 안을 비워 인용문 속 마침표를 문장 끝으로 세지 않게 한다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `'a "b. c" d' → "a   d"`

### scv_lower
- 역할: ASCII 대문자만 소문자로 바꾼다 — 공백 · 한글 · 기호는 그대로(맥 기본 bash 3.2 에서도 됨)
- 위치: scripts/lib/text.sh · @pure · sh
- 예: `" AbC-1 " → " abc-1 "`
- 예: `"한글 OK" → "한글 ok"`
- 예: `"" → ""`

### scv_mp_guide_rebase
- 역할: 기록된 가이드 경로 · 표시 명령을 지금 설치본 자리로 바꿔 쓴다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'m\nGUIDE_FILE: /old/1.0/prompting/g.md\nGUIDE_MARK_CMD: bash "/old/1.0/scripts/model-prompting.sh" mark --model "m"' /new/prompting /new/scripts/model-prompting.sh → $'m\nGUIDE_FILE: /new/prompting/g.md\nGUIDE_MARK_CMD: bash "/new/scripts/model-prompting.sh" mark --model "m"'`
- 예: `$'none' /new/prompting /new/s.sh → "none"`

### scv_mp_normalize_id
- 역할: 모델 id 를 앞뒤 공백 없이 소문자로 바꾸고 끝의 "[…]" 표기를 지운다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"  Model-X-4[1m] " → "model-x-4"`
- 예: `"X-5" → "x-5"`

### scv_mp_principle_text
- 역할: 구역에서 표식 줄과 통로별 해로운 변경 줄을 뺀 원칙 전문을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'tag: [P]\nbody\nharm-text: x' → "body"`
- 예: `plain → "plain"`

### scv_mp_register_normalize
- 역할: 제출 텍스트를 탭 구분 세 칸으로 맞춘다(" | " 도 받고 앞뒤 공백을 자른다)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'a | msg | v\n\nb\tna\tv2' → $'a\tmsg\tv\nb\tna\tv2\n'`

### scv_mx_strip_comment
- 역할: 값 뒤의 " # 주석" 과 감싼 따옴표를 떼고 남은 값을 낸다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `'"my title" # note' → "my title"`

### scv_mx_trim
- 역할: 앞뒤 공백 · 탭 · 줄바꿈을 지운다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `"  a b  " → "a b"`

### scv_plan_norm_req
- 역할: 요건 글 하나를 맞대기 좋게 다듬는다 — 끝의 부정 말(안 함 · 하지 않음 · 않는다 · 금지)과 문장 부호 · 앞뒤 공백을 떼고, 단계 꼬리(" — " 뒤)를 뗀다
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `"결제 한도 변경 안 함" → "결제 한도 변경"`
- 예: `"끝난 단계를 다시 쓰거나 지우는 일 — 아무거나" → "끝난 단계를 다시 쓰거나 지우는 일"`
- 예: `"  화면 만들기.  " → "화면 만들기"`

### scv_tc_words
- 역할: 글을 맞대기용 낱말들로 나눈다 — 2자 이상, 끝 조사를 떼고, 흔한 말은 뺀다(빈칸으로 이음)
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"환불 버튼을 추가해" → "환불 버튼 추가해"`
- 예: `"결제 화면 기능" → "결제"`
- 예: `"x" → ""`
