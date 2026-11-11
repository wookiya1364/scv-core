# 변환 — 한 표기를 다른 표기로 바꾼다 — 경로 · 날짜 · 단위 · 인코딩

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 40개.

### below_raw_root
- 역할: 경로에서 원자료 폴더 뿌리까지를 떼어 낸다 — 뿌리 아래 마디만 연결 검사를 하려고
- 위치: scripts/readpath.sh · @pure · sh
- 예: `"scv/raw/sub/a.md" "scv/raw" → "sub/a.md"`
- 예: `"scv/raw" "scv/raw" → ""`
- 예: `"x/y" "scv/raw" → "x/y"`

### key_of
- 역할: 폴더 경로를 사진 파일 이름으로 바꾼다 — 슬래시 · 빈칸을 밑줄로
- 위치: scripts/turn-check.sh · @pure · sh
- 예: `"/Users/a/b c" → "_Users_a_b_c"`

### pb_scale_args
- 역할: 예시의 인자 글에서 여러 줄 값은 줄을, 여러 줄 값이 없으면 낱말이 여럿인 값은 낱말을 N번 되풀이한다(늘릴 값이 없으면 그대로 내고 1)
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'$\'a\\nb\' "x y"' 2 → $'$\'a\\nb\\na\\nb\' "x y"'`
- 예: `'"x y" k' 2 → '"x y x y" k'`
- 예: `'"1.2.3" k' 2 → '"1.2.3" k' [1]`

### pb_times_secs
- 역할: 셸의 times 출력 글(분 · 초 꼴 네 값)을 모두 더한 초로 낸다
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'0m0.010s 0m0.020s\n0m1.000s 0m0.500s' → "1.530"`
- 예: `$'1m2.000s 0m0.000s\n0m0.000s 0m0.000s' → "62.000"`

### scv_as_group_of
- 역할: 파일 경로에서 묶음 이름을 낸다 — 보관된 계획의 네 문서는 폴더 이름 하나로 합친다
- 위치: scripts/lib/archive-search.sh · @pure · sh
- 예: `scv/archive/20260101-a-x/PLAN.md → "20260101-a-x"`
- 예: `scv/archive/20260101-a-x/TESTS.md → "20260101-a-x"`
- 예: `scv/DECISIONS.md → "DECISIONS"`

### scv_dreams_day
- 역할: YYYYMMDD 를 YYYY-MM-DD 로 바꾼다(모양이 다르면 그대로)
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `20261001 → '2026-10-01'`
- 예: `abc → 'abc'`

### scv_dreams_period_ord
- 역할: 날짜 YYYYMMDD 를 기간 단위(dekad · month)의 순번 정수로 바꾼다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `20261015 dekad → '72964'`
- 예: `20261015 month → '24321'`

### scv_dreams_period_range
- 역할: 기간 순번과 단위로 "시작 끝" YYYYMMDD 를 낸다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `72964 dekad → '20261011 20261020'`
- 예: `72963 dekad → '20261001 20261010'`

### scv_dreams_tag
- 역할: «  » 로 적은 짧은 HTML 조각을 꺾쇠 태그로 바꾼다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `"«b»hi«/b»" → '<b>hi</b>'`

### scv_evidence_build
- 역할: 사건 줄들을 근거 목록으로 바꾼다 — 실행을 시험 · SCV 기록 · 실행으로 가르고, 실패는 끝 코드 · 출력 표시 · 뒤 실행 알림으로 정한다
- 위치: scripts/lib/finish-report.sh · @pure · sh
- 예: `$'T\x1frun\x1f시험 실행\x1fbash tests/test-a.sh | tail\x1f0\x1f1\x1f\x1f' → $'test\x1f시험 실행\x1ffail\x1fbash tests/test-a.sh | tail'`
- 예: `$'T\x1frun\x1f읽기\x1fgrep -n x tests/test-a.sh\x1f0\x1f0\x1f\x1f' → $'run\x1f읽기\x1fok\x1fgrep -n x tests/test-a.sh'`
- 예: `"" → ""`

### scv_graph_normpath
- 역할: 경로의 "./" 와 "a/../" 를 접고 겹친 슬래시를 하나로 줄인다 (앞의 "/" 는 유지하지 않는다)
- 위치: scripts/lib/graph.sh · @pure · sh
- 예: `"./a/b/../c.md" → "a/c.md"`
- 예: `"a/./b//c" → "a/b/c"`

### scv_hstate_mark
- 역할: 상태를 "규약을 읽었다"(protocol=1)로 바꾸고, 새 지문을 주면 그것으로 갈아 끼운다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `$'s1\x1f0\x1f3\x1fab12\x1f09:30\x1f' cafe0000 → $'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fcafe0000'`

### scv_hstate_reload
- 역할: 상태 · 세션 번호 · 사건(prompt|reset) · N 으로 규약 재읽기 여부를 반영한 새 상태를 낸다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' s1 prompt 0 → $'s1\x1f1\x1f4\x1fab12\x1f09:30\x1fdeadbeef'`
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' s2 prompt 0 → $'s2\x1f0\x1f1\x1f\x1f\x1f'`
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' s1 reset 0 → $'s1\x1f0\x1f3\x1fab12\x1f09:30\x1f'`

### scv_mp_guides_dir
- 역할: 프로필 값이 절대 경로면 그대로, 상대 경로면 코어 루트 아래 경로로 바꾼다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `/root guides → "/root/guides"`
- 예: `/root /abs/g → "/abs/g"`
- 예: `/root "" → ""`

### scv_mp_principle_lang
- 역할: SCV_LANG 값을 원칙 구역 이름(korean · english · japanese)으로 바꾼다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `ko → "korean"`
- 예: `"" → "english"`
- 예: `FR → "fr"`

### scv_mp_restamp
- 역할: 읽음 기록의 옛 지문을 새 지문으로 바꾼 줄을 낸다(옛 지문이 다르면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'old\x1fm' old new → $'new\x1fm'`
- 예: `$'zzz\x1fm' old new → ""`

### scv_mp_turn_restamp
- 역할: 이번 턴 기록의 옛 지문을 새 지문으로 바꾼 줄을 낸다(맞지 않으면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'old\x1fm\x1fload\x1fk' old new → $'new\x1fm\x1fload\x1fk'`
- 예: `$'zz\x1fm\x1fload\x1fk' old new → ""`

### scv_mx_civil_to_minutes
- 역할: "YYYY-MM-DD HH:MM" 을 1970-01-01 00:00 기준 분 수로 바꾼다 (형식이 아니면 빈 값)
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `"1970-01-02 00:30" → "1470"`
- 예: `"nope" → ""`

### scv_mx_fmt10
- 역할: 10배 한 정수를 소수 한 자리 "d.d" 로 바꾼다 (빈 값이면 "—")
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `25 → "2.5"`
- 예: `"" → "—"`

### scv_mx_resolve_conv_path
- 역할: 계획서에 적힌 대화 경로를 SCV_DIR 기준 후보 경로 두 줄(그대로 · archive 아래)로 바꾼다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `"scv/conversations/c1.md" → $'conversations/c1.md\nconversations/archive/c1.md'`

### scv_obsolete_frontmatter
- 역할: PLAN.md 글의 앞머리에서 세 칸(status · obsoleted_at · obsoleted_by)만 폐기로 바꾼다 — 이미 obsolete 면 글을 그대로 돌려준다
- 위치: scripts/lib/obsolete.sh · @pure · sh
- 예: `$'---\ntitle: a\nstatus: done\n---\n# a' "2026-11-02" "new-x" → $'---\ntitle: a\nstatus: obsolete\nobsoleted_at: 2026-11-02\nobsoleted_by: new-x\n---\n# a'`
- 예: `$'---\nstatus: obsolete\nobsoleted_at: 2026-10-01\n---' "2026-11-02" "new-x" → $'---\nstatus: obsolete\nobsoleted_at: 2026-10-01\n---'`
- 예: `"" "2026-11-02" "new-x" → ""`

### scv_plan_fm_drop
- 역할: PLAN.md 글의 앞머리에서 한 칸의 줄을 지운다 — 칸이 없으면 글을 그대로 돌려준다
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'---\nstatus: paused\npaused_by: b\n---\n# a' "paused_by" → $'---\nstatus: paused\n---\n# a'`
- 예: `$'---\nstatus: paused\n---' "paused_by" → $'---\nstatus: paused\n---'`
- 예: `"# a" "status" → "# a"`

### scv_plan_fm_set
- 역할: PLAN.md 글의 앞머리에서 한 칸을 바꾼다 — 칸이 없으면 앞머리 끝(닫는 --- 바로 앞)에 새로 둔다
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'---\nstatus: planned\n---\n# a' "status" "paused" → $'---\nstatus: paused\n---\n# a'`
- 예: `$'---\nstatus: paused\n---\n# a' "paused_by" "b" → $'---\nstatus: paused\npaused_by: b\n---\n# a'`
- 예: `"# a" "status" "paused" → "# a"`

### scv_plan_insert_step
- 역할: Suggested path 의 after 번 단계 뒤에 새 단계를 끼우고 뒤 단계 번호를 하나씩 민다 — after 가 마지막 번호 이상이면 맨 끝, 0 이면 맨 앞
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'## Suggested path\n\n1. [x] a\n2. b\n\n## Links' 1 "c" → $'## Suggested path\n\n1. [x] a\n2. c\n3. b\n\n## Links'`
- 예: `$'## Suggested path\n1. a' 5 "c" → $'## Suggested path\n1. a\n2. c'`
- 예: `$'## Suggested path\n1. a' 0 "c" → $'## Suggested path\n1. c\n2. a'`

### scv_plan_link_return
- 역할: 새 계획 B 에 끝나면 돌아갈 계획 A 를 적는다 — return_to 칸과 변경 이력 "연결" 사건 하나(돌아갈 계획 제목 · 이유)
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'---\nstatus: planned\n---\n# b' "a" "결제 화면" "2026-11-09" "다른 목표" → $'---\nstatus: planned\nreturn_to: a\n---\n# b\n\n## 변경 이력\n\n- **2026-11-09 연결** — 끝나면 돌아갈 계획: 결제 화면\n  - 이유: 다른 목표'`
- 예: `"# b" "a" "a" "2026-11-09" "x" → $'# b\n\n## 변경 이력\n\n- **2026-11-09 연결** — 끝나면 돌아갈 계획: a\n  - 이유: x'`

### scv_plan_mark_pause
- 역할: 계획 A 를 보류로 바꾼다 — status: paused · paused_by · resume_at 칸과 변경 이력 "보류" 사건 하나(먼저 할 계획 제목 · 다시 시작 단계 · 이유)
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'---\nstatus: in_progress\n---\n# a' "b" "로그 정리" 2 "2026-11-09" "다른 목표" → $'---\nstatus: paused\npaused_by: b\nresume_at: 2\n---\n# a\n\n## 변경 이력\n\n- **2026-11-09 보류** — 먼저 할 계획: 로그 정리\n  - 다시 시작: 2단계부터\n  - 이유: 다른 목표'`
- 예: `"# a" "b" "b" 1 "2026-11-09" "x" → $'# a\n\n## 변경 이력\n\n- **2026-11-09 보류** — 먼저 할 계획: b\n  - 다시 시작: 1단계부터\n  - 이유: x'`

### scv_plan_mark_resume
- 역할: 보류였던 계획 A 를 진행 중으로 되돌린다 — paused_by · resume_at 칸을 지우고 변경 이력 "재개" 사건 하나(끝난 계획 제목 · 다시 시작 단계)
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'---\nstatus: paused\npaused_by: b\nresume_at: 2\n---\n# a' "로그 정리" "2026-11-10" → $'---\nstatus: in_progress\n---\n# a\n\n## 변경 이력\n\n- **2026-11-10 재개** — 끝난 계획: 로그 정리\n  - 다시 시작: 2단계부터'`
- 예: `$'---\nstatus: paused\n---\n# a' "b" "2026-11-10" → $'---\nstatus: in_progress\n---\n# a\n\n## 변경 이력\n\n- **2026-11-10 재개** — 끝난 계획: b\n  - 다시 시작: 1단계부터'`

### scv_plan_shift_progress
- 역할: 단계를 after 번 뒤에 끼운 뒤, 변경 이력의 진행 줄("- **날짜 진행** — M단계 …")에서 M 이 after 보다 크면 M+1 로 민다 — 옛 진행 기록이 새 단계에 붙지 않게(0.87.4). 진행 줄이 아닌 줄은 그대로
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'- **d 진행** — 3a단계 막힘: k\n- **d 진행** — 2단계 끝: j' 2 → $'- **d 진행** — 4a단계 막힘: k\n- **d 진행** — 2단계 끝: j'`
- 예: `$'- **d 추가** — 1단계 뒤에 새 단계' 0 → $'- **d 추가** — 1단계 뒤에 새 단계'`
- 예: `$'# a\n본문 3단계' 1 → $'# a\n본문 3단계'`

### scv_reg_rewrite_line
- 역할: 시험 줄이면 그 명령을 기록된 종료 코드 '( exit N )' 로 바꾸고 앞 공백 · 꼬리는 남긴다 — 표에 없으면 그대로
- 위치: scripts/lib/regression-memo.sh · @pure · sh
- 예: `"  bash t/a.sh >/dev/null || fail a" $'bash t/a.sh\t1' → "  ( exit 1 ) >/dev/null || fail a"`
- 예: `"bash t/b.sh" $'bash t/a.sh\t0' → "bash t/b.sh"`
- 예: `"bash t/a.sh && bash t/b.sh" $'bash t/a.sh\t0\nbash t/b.sh\t1' → "( exit 0 ) && ( exit 1 )"`

### scv_show_real_lines
- 역할: \x1e 로 이은 글을 줄바꿈으로 나눈 글로 바꾼다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `$'a\036b' → $'a\nb'`
- 예: `"" → ""`

### scv_show_real_local_date
- 역할: 기록 시각(UTC 또는 ±시간대)과 지역 오프셋(분)으로 그 지역의 날짜 YYYYMMDD 를 낸다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `"2026-10-01T20:30:00Z" 540 → '20261002'`
- 예: `"2026-03-01T00:30:00+09:00" 0 → '20260228'`
- 예: `"nope" 0 → ""`

### scv_show_real_merge
- 역할: 분류된 턴 줄들에서 답이 yes 인 턴의 보여 줌 칸만 1 로 바꾼다
- 위치: scripts/lib/show-real.sh · @deterministic · sh
- 예: `$'s1\t2026-10-01T01:00:00Z\t1\t0\t1\t0\t0' $'A\tk\ts1\t2026-10-01T01:00:00Z\tb\tyes' → $'s1\t2026-10-01T01:00:00Z\t1\t1\t1\t0\t0'`

### scv_show_real_offset
- 역할: +HHMM · -HHMM 모양의 오프셋을 분으로 바꾼다(모양이 다르면 0)
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `+0900 → '540'`
- 예: `-0530 → '-330'`
- 예: `abc → '0'`

### scv_show_real_range
- 역할: 기간 글 YYYY-MM-DD..YYYY-MM-DD 를 "시작 끝" YYYYMMDD 두 값으로 바꾼다(잘못된 기간은 빈 값)
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `"2026-10-01..2026-10-11" → '20261001 20261011'`
- 예: `"2026-10-11..2026-10-01" → ""`

### scv_stop_notice
- 역할: 막는 이유들을 다음 턴 안내 줄들로 바꾼다
- 위치: scripts/lib/stop-gates.sh · @pure · sh
- 예: `$'[SCV 확인 범위] 줄이 빠졌다\n[SCV 선택지] 선택 창으로' → $'[SCV 직전 답] [SCV 확인 범위] 줄이 빠졌다\n[SCV 직전 답] [SCV 선택지] 선택 창으로\n[SCV 직전 답] 이번 답부터 지켜라 — 직전 답을 다시 쓰거나 고쳐 쓰지 말 것.'`
- 예: `"" → ""`

### scv_tc_abs_paths
- 역할: 저장소 맨 위 경로와 그 안의 상대 경로 줄들을 이어 절대 경로 줄들로 바꾼다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"/r" $'a.ts\nsrc/b.ts' → $'/r/a.ts\n/r/src/b.ts'`
- 예: `"/r" "" → ""`

### scv_tc_plan_lines
- 역할: 계획 글 여러 개의 이력 · 단계 줄을 모아 정렬한 묶음으로 만든다 — 시작 · 끝 묶음의 차이가 '새로 생긴 줄'
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `$'# a\n- **2026-11-09 진행** — 1단계: x\n본문\n  - 요청: y (요청 ab)' → $'  - 요청: y (요청 ab)\n- **2026-11-09 진행** — 1단계: x'`
- 예: `"본문만" → ""`

### scv_tc_record_globs
- 역할: 기록 폴더의 실제 경로들 중 이 저장소 뿌리 아래에 있는 것을 '뺄 글롭'(: 로 이음)으로 바꾼다 — 기록 폴더를 다른 저장소로 연결해 둔 프로젝트에서 그 안 파일을 '일'로 세지 않으려고
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"/b" $'/b/core/raw\n/b/core/journal\n/x/y' → "core/raw/*:core/journal/*"`
- 예: `"/b" "/b" → "*"`
- 예: `"/b" "" → ""`

### scv_tc_req_tag
- 역할: 기록 줄에 붙일 요청 꼬리를 만든다 — 사용자 원문 앞부분(줄바꿈은 빈칸, 80자) + "(요청 <번호>)"
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"ab12cd34" "전사 체력 87로 수정해" → "요청: 전사 체력 87로 수정해 (요청 ab12cd34)"`
- 예: `"ab12cd34" $'두 줄\n요청' → "요청: 두 줄 요청 (요청 ab12cd34)"`
- 예: `"" "x" → ""`

### settings_merge_defaults
- 역할: 사용자 JSON 에 기본값 JSON 을 깔아 병합한다 — 사용자 값이 이긴다
- 위치: scripts/lib/settings.sh · @deterministic · sh
- 예: `'{"a":1}' '{"a":0,"b":2}' → $'{\n  "a": 1,\n  "b": 2\n}'`
