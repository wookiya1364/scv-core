# 판정/answer — 답 · 메시지 글을 보고 판정한다 — 표가 있나, 묻는 글인가, 확인인가

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 24개.

### _scv_choice_blank
- 역할: 줄이 빈 줄(ASCII 공백 · NBSP · 전각 공백뿐)이면 성공(0), 아니면 실패(1)로 알린다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `"   " → ""`
- 예: `"a" → [1]`

### _scv_choice_cue_real
- 역할: 글 속 요청 말이 "언제든지 · 얼마든지" 같은 맺음 인사가 아닌 진짜 요청이면 성공(0), 맺음 인사뿐이면 실패(1)로 알린다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `"무엇인지 알려 주세요" "알려 주세요" → ""`
- 예: `"언제든지 알려 주세요" "알려 주세요" → [1]`

### _scv_choice_has_text
- 역할: 글에 공백 · 굵게 · 닫는 괄호 말고 실제 글자가 있으면 성공(0), 없으면 실패(1)로 알린다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `"a" → ""`
- 예: `"  ** " → [1]`

### scv_answer_lint
- 역할: 답 본문의 골격(다시 쓴 요청 위치 · 줄글 문단 길이 · 불릿 어미 · 첫 내용의 코드값 · 결정표 추천 칸)이 계약을 벗어난 줄들을 낸다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `$'> **다시 쓴 요청**: x\n\n**주제**\n- 결과임\n- 풀이함\n' → ""`
- 예: `$'결론이다. 둘째. 셋째.\n' 2 → "prose-long=3>2"`
- 예: `$'결론이다.\n\n> **다시 쓴 요청**: x\n' → "rewrite-not-top"`

### scv_as_kind_of
- 역할: 파일 경로 모양만 보고 기록의 종류(계획 · 검사 · 대화 · 결정 · 기타 …)를 정한다
- 위치: scripts/lib/archive-search.sh · @pure · sh
- 예: `scv/archive/x/PLAN.md → "계획"`
- 예: `scv/conversations/a.md → "대화"`
- 예: `scv/DECISIONS.md → "결정"`
- 예: `README.md → "기타"`

### scv_asks_in_text
- 역할: 답이 사용자에게 글로 고르게 하거나 묻는 꼴로 끝나면 1, 아니면 0 을 낸다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `$'작업을 끝냈다.\n어느 쪽으로 할까요?' → "1"`
- 예: `$'작업을 끝냈다.' → "0"`
- 예: `$'둘 중 번호로 답해 주세요.\n1. A\n2. B' → "1"`

### scv_choice_q_asks
- 역할: 물음표 뒤 글이 사용자에게 답을 요청하거나 추천을 달고 있으면 1, 바로 답이 오는 혼잣말 질문이면 0 을 낸다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `" 추천은 A입니다." → "1"`
- 예: `"네, 그렇습니다." → "0"`

### scv_dreams_pasted
- 역할: 사람 메시지가 붙여 넣은 글로 보이면 종료 0, 사람이 쓴 요청이면 1
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'```\nx\n```' → [0]`
- 예: `"고쳐 줘" → [1]`

### scv_echo_check
- 역할: 이번 턴 기록의 지문과 표식 지문을 견줘 skip | ok | missing | mismatch 중 하나를 낸다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `abc abc 1 yes → "ok"`
- 예: `"" abc 1 yes → "missing"`
- 예: `abc abc 0 yes → "skip"`

### scv_is_rewrite_quote
- 역할: 한 줄이 다시 쓴 요청 인용 줄(> **다시 쓴 요청**: · > **Rewritten request**: · > **書き直した依頼**:)인지 1|0 으로 정한다
- 위치: scripts/lib/text.sh · @pure · sh
- 예: `"> **다시 쓴 요청**: 정리해 줘" → "1"`
- 예: `"  >Rewritten request: fix" → "1"`
- 예: `"다시 쓴 요청: 인용 아님" → "0"`
- 예: `"> 다른 인용" → "0"`

### scv_lint_bullet_polite
- 역할: 불릿 한 줄이 존댓말 서술형('~습니다' · '~해요')으로 끝나면 1, 개조식 · 물음이면 0 을 낸다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `"통과했습니다." → "1"`
- 예: `"README 검사 통과함" → "0"`
- 예: `"이대로 쓸까요?" → "0"`

### scv_mp_answer_has_problem_table
- 역할: 답에 "문제 표"(위치 · 깨지는 것 칸 등)가 있는지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'| 위치 | 깨지는 것 |\n|---|---|' → "1"`
- 예: `"문제 없음" → "0"`

### scv_mp_answer_has_quote
- 역할: 답 본문의 코드 블록 밖에 ">" 인용 줄이 있는지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'text\n> quote' → "1"`
- 예: `$'```\n> in code\n```' → "0"`

### scv_mp_answer_rewrite_on_top
- 역할: 답의 첫 내용 줄(구분 줄로 나뉜 조각마다)이 다시 쓴 요청 인용인지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'> **다시 쓴 요청**: 정리\n\n**결과**' → "1"`
- 예: `$'결론이다.\n\n> **다시 쓴 요청**: 정리' → "0"`
- 예: `$'끝났음\n\x1d\n> **다시 쓴 요청**: 정리\n중간 보고' → "1"`

### scv_mp_answer_shows_rewrite
- 역할: 답의 코드 블록 밖 인용 줄에 다시 쓴 요청이 보이는지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'> **다시 쓴 요청**: 무엇을 한다' '무엇을 한다' → "1"`
- 예: `$'본문만' '무엇을 한다' → "0"`

### scv_mp_prompt_kind
- 역할: 프롬프트가 알림 태그 블록뿐이면 auto, 사람이 쓴 글이 섞이면 human 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"<task-notification>done</task-notification>" "task-notification" → "auto"`
- 예: `"hi <task-notification>x</task-notification>" "task-notification" → "human"`

### scv_rc_is_normative
- 역할: 본문에 규범 동사(never · must · 반드시 등)가 있으면 참
- 위치: scripts/lib/rule-constitution.sh · @pure · sh
- 예: `'You must run tests' → ""`
- 예: `'절대 지우지 마라' → ""`
- 예: `'Tests are nice' → "" [1]`

### scv_rc_is_precedence
- 역할: 본문에 우선순위 어휘(overrides · 우선한다 등)가 있으면 참
- 위치: scripts/lib/rule-constitution.sh · @pure · sh
- 예: `'This rule overrides the others' → ""`
- 예: `'Write tests first' → "" [1]`

### scv_rc_is_reference
- 역할: 본문이 Top-level rules 를 가리키는 참조형이면 참
- 위치: scripts/lib/rule-constitution.sh · @pure · sh
- 예: `'See Top-level rules above' → ""`
- 예: `'Write tests' → "" [1]`

### scv_show_real_classify
- 역할: 사람 턴 줄마다 바뀜 · 보여 줌 · 완료 · 수정 요구 · 확인 질문 수를 가려 한 줄로 낸다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `$'s1\t2026-10-01T01:00:00Z\tERTq\tfix it\tdone\tAll 5 passed.\t5 passed' → $'s1\t2026-10-01T01:00:00Z\t1\t0\t1\t0\t0'`

### scv_show_real_is_confirm
- 역할: 질문이 계속할지와 고칠 점을 함께 묻는 확인인지 1 또는 0 으로 낸다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `"이대로 계속할까요, 고칠 점이 있나요?" → '1'`
- 예: `"어떤 방식으로 할까요?" → '0'`

### scv_show_real_is_correction
- 역할: 사람 메시지가 고쳐 달라는 말인지 단서 낱말(한 · 영 · 일)로 보고 1 또는 0 으로 낸다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `"이건 틀렸어" → '1'`
- 예: `"looks good" → '0'`
- 예: `"fix this" → '1'`

### scv_show_real_is_nochange
- 역할: 모델의 글에 결과물 변화 없음 표시가 있는지 1 또는 0 으로 낸다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `"결과물 변화 없음" → '1'`
- 예: `"done" → '0'`

### scv_show_real_quotes
- 역할: 실행 출력이 묻는 글 안에 그대로 인용됐는지 1 또는 0 으로 낸다(셋째 인자 line 이면 인용된 출력 줄)
- 위치: scripts/lib/show-real.sh · @deterministic · sh
- 예: `"5 passed" "all 5 passed today" → '1'`
- 예: `"5 passed" "nothing here" → '0'`
