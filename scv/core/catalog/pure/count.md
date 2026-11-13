# 세기 — 개수 · 길이 · 합계를 센다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 25개.

### pb_gpu_summary
- 역할: GPU 표본 줄들("사용률<탭>메모리 MB")과 시작 전 메모리 · 시작 전 사용률에서 "평균 사용률 %<탭>늘어난 메모리 MB<탭>오른 사용률 %p"를 낸다(표본이 없으면 "-" 셋)
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'40\t1100.0\n60\t1300.0' 1000.0 10 → $'50\t300.0\t40'`
- 예: `$'10\t1000.0' 1000.0 15 → $'10\t0.0\t0'`
- 예: `'' 1000.0 0 → $'-\t-\t-'`

### pb_median
- 역할: 빈칸으로 나눈 수들의 가운데값을 소수 셋째 자리로 낸다(짝수 개면 가운데 둘의 평균, 수가 없으면 "-")
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `"3.000 1.000 2.000" → "2.000"`
- 예: `"4.0 1.0 3.0 2.0" → "2.500"`
- 예: `"" → "-"`

### pb_ratio
- 역할: 앞 값과 뒤 값에서 뒤 ÷ 앞을 소수 둘째 자리로 낸다(한쪽이 숫자가 아니거나 앞 값이 0이면 "-")
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `3.000 3.750 → "1.25"`
- 예: `10 9 → "0.90"`
- 예: `0 5 → "-"`

### pb_reps_next
- 역할: 잰 CPU 초와 되풀이 수를 보고 다음 되풀이 수를 낸다 — 0.2초에 못 미치면 0.3초가 되도록 늘린다(2000번까지)
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `0.010 5 → "150"`
- 예: `0.250 5 → "5"`
- 예: `0.000 5 → "2000"`

### pb_scale_ratio
- 역할: 1배 값과 4배 값에서 배수를 소수 한 자리로 낸다(한쪽이 숫자가 아니거나 1배 값이 0이면 "-")
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `22.286 386.600 → "17.3"`
- 예: `4.492 13.739 → "3.1"`
- 예: `5 - → "-"`
- 예: `0.000 3.0 → "-"`

### scv_as_count_terms
- 역할: 한 줄에 낱말 목록 중 몇 개가 들어 있는지 센다(대소문자 무시)
- 위치: scripts/lib/archive-search.sh · @deterministic · sh
- 예: `'Fix the Login bug' $'login\nbug\nlogout' → "2"`
- 예: `'nothing' $'login' → "0"`

### scv_dreams_distribution
- 역할: 계획마다 보관까지의 사람 질의 수와 근거 턴 id 를 센다(마지막 줄 #open 은 보관 뒤 질의 수)
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'s1\t1\t2026-10-01T01:00:00Z\tfix it\ns1\t2\t2026-10-02T01:00:00Z\tdo more' $'20261002\tplan-a' 0 → $'plan-a\t20261002\t2\ts1/1\n#open\t0'`

### scv_dreams_periods
- 역할: 사람 턴 줄들과 보관 줄들을 기간별 질의 · 보관 수와 비율 줄로 센다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'s1\t1\t2026-10-01T01:00:00Z\tfix it\ns1\t2\t2026-10-02T01:00:00Z\tdo more' $'20261002\tplan-a' 0 month → $'20261001\t20261031\t2\t1\t2.0'`

### scv_dreams_totals
- 역할: 기간 줄들에서 마지막 보관이 있는 기간까지의 질의 합과 보관 합을 센다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'20261001\t20261010\t5\t0\t-\n20261011\t20261020\t3\t2\t1.5' → $'8\t2'`

### scv_graft_ext_histogram
- 역할: 표준입력 파일 경로들에서 "확장자 개수" 표를 만든다(확장자 없는 파일은 뺌, 순서 불정)
- 위치: scripts/lib/graft.sh · @deterministic · sh
- 예: `<<< $'a.py\nb.py\nREADME' → $'py\t2'`

### scv_graft_supported_count
- 역할: 확장자 히스토그램에서 지원 언어 파일 수의 합을 낸다
- 위치: scripts/lib/graft.sh · @pure · sh
- 예: `$'py\t3\nmd\t5\nts\t2' → "5"`

### scv_graph_cochange
- 역할: 계획별 파일 목록(touches 줄들)에서 함께 바뀐 파일 쌍과 횟수 · 근거 slug 를 "a\x1fb\x1f횟수\x1f근거" 줄들로 센다 (jq 필요)
- 위치: scripts/lib/graph.sh · @deterministic · sh
- 예: `$'p1\x1fa b c\np2\x1fa b\n' → $'a\x1fb\x1f2\x1fp1 p2\na\x1fc\x1f1\x1fp1\nb\x1fc\x1f1\x1fp1'`

### scv_lint_hangul_ratio
- 역할: 글에서 한글 글자가 한글 · 영문 글자 중 몇 퍼센트인지 센다(앞 4000바이트만)
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `"로그인 버그를 고침" → "100"`
- 예: `"fixed the login bug" → "0"`
- 예: `"" → "0"`

### scv_lint_sentences
- 역할: 한 덩어리 글의 문장 수를 센다 — 따옴표 · 괄호 안 마침표와 "0.49.1" 같은 숫자는 세지 않는다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `"결론이다. 둘째. 셋째." → "3"`
- 예: `'버전 0.49.1 이다 "a. b" 끝.' → "1"`
- 예: `"" → "0"`

### scv_mp_age_days
- 역할: 가져온 날짜부터 오늘까지 지난 일수를 센다(형식 오류면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `2026-01-01 2026-01-11 → "10"`
- 예: `2026-01-11 2026-01-01 → "0"`

### scv_mx_aggregate
- 역할: 지표 줄들을 값 있는 수 · 전체 수 · 합 · 평균x10 · 중앙값x10 한 줄로 요약한다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'a\t10\nb\t20\nc\tnone\n' → $'2\t3\t30\t150\t150'`

### scv_mx_count_answers
- 역할: 저널에서 답 기록 머리줄을 모델 id 별로 세어 많은 순으로 낸다 (표기 없는 답은 라벨 "-")
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'### [09:00:00] assistant · m1\n### [09:01:00] assistant\n### [09:02:00] assistant · m1\n' → $'m1\t2\n-\t1'`

### scv_mx_count_turns
- 역할: 대화 파일 텍스트의 "## Turn N" 헤딩 수를 센다 (코드 블록 안은 제외)
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'## Turn 1 — a\n```\n## Turn 2 — x\n```\n## Turn 3 — b\n' → "2"`

### scv_mx_metric_lead_time
- 역할: 색인의 slug 마다 가장 이른 adopted 에서 archived 까지 걸린 분 수를 낸다 (없으면 none)
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'a\tx\ty\n' $'a\tadopted\t100\na\tarchived\t160\n' → $'a\t60'`

### scv_show_real_count
- 역할: 분류된 턴 줄들을 두 기간(켜기 전 · 켠 뒤)별로 세션 · 턴 · 바뀐 턴 · 보여 준 턴 등으로 센다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `$'s1\t2026-10-01T01:00:00Z\t1\t1\t1\t0\t1\ns1\t2026-10-02T01:00:00Z\t1\t0\t1\t1\t0' 0 "20261001 20261001" "20261002 20261002" → $'before\t1\t1\t1\t1\t0\t1\nafter\t1\t1\t1\t0\t1\t0'`

### scv_show_real_judge_count
- 역할: 판정자 답 줄들에서 기간마다 판정한 턴 · 그중 보여 줌 · 판정 못 한 턴을 센다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `$'A\tk\ts\tt\tb\tyes\nA\tk\ts\tt\tb\tno\nA\tk\ts\tt\ta\tunjudged' → $'before\t2\t1\t0\nafter\t0\t0\t1'`

### scv_tc_overlap_count
- 역할: 항목 낱말들 중 메모 낱말에 있는 것의 수와 항목 낱말 수를 "겹친 수 전체 수"로 낸다 — 같은 낱말은 한 번만 센다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"환불" "환불 버튼" → "1 1"`
- 예: `"가나 다라 마바 사아" "가나 사아 자차" → "2 4"`
- 예: `"" "가나" → "0 0"`

### scv_tc_req_count
- 역할: 계획 글에서 새로 생긴 줄들 중 이번 턴 요청 번호 꼬리 "(요청 <번호>)" 가 든 줄의 수를 센다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `$'  - 요청: 고쳐 줘 (요청 ab12cd34)\n- x' "ab12cd34" → "1"`
- 예: `$'  - 요청: 고쳐 줘 (요청 ab12cd34)' "ffff0000" → "0"`
- 예: `"x" "" → "0"`

### scv_tc_step_calls
- 역할: 대화 기록 줄들에서 시작 시각 뒤에 어시스턴트가 그 도구를 부른 줄을 센다 — 도구 이름이 글에만 나온 줄 · 다른 도구 · 시작 앞의 호출 · JSON 이 아닌 줄은 세지 않는다
- 위치: scripts/lib/turn-check.sh · @deterministic · sh
- 예: `'{"type":"assistant","timestamp":"2026-01-02T00:00:00.000Z","message":{"content":[{"type":"tool_use","name":"t"}]}}' t "2026-01-01T00:00:00" → "1"`
- 예: `'{"type":"assistant","timestamp":"2025-12-31T00:00:00.000Z","message":{"content":[{"type":"tool_use","name":"t"}]}}' t "2026-01-01T00:00:00" → "0"`
- 예: `'{"type":"user","timestamp":"2026-01-02T00:00:00.000Z","message":{"content":"t 를 불러라 — tool_use"}}' t "2026-01-01T00:00:00" → "0"`
- 예: `"" t "2026-01-01T00:00:00" → "0"`
- 예: `"x" t "" → "0"`

### scv_tc_struct_count
- 역할: 계획 글에서 새로 생긴 줄들 중 구조 줄(이력 머리: 추가 · 보류 · 연결 · 재개 · 다시 하기 · 진행 · 예외)의 수를 센다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `$'- **2026-11-09 진행** — 6단계: x\n  - 요청: y (요청 ab12cd34)\n- **2026-11-09 10:00 선택** — 답: z' → "1"`
- 예: `$'- **2026-11-09 추가** — 7단계 뒤에 새 단계\n그냥 메모' → "1"`
- 예: `"그냥 메모" → "0"`
