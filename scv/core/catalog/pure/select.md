# 고르기 — 여럿 중 일부를 골라내거나 순서를 매긴다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 42개.

### attachment_scope_filter
- 역할: 표준입력 줄들에서 슬러그가 든 줄만 남긴다 — 슬러그가 비면 전부 통과
- 위치: scripts/lib/attachment-scope.sh · @pure · sh
- 예: `my-plan <<< $'my-plan/a.md\nother/b.md' → "my-plan/a.md"`
- 예: `'' <<< $'x\ny' → $'x\ny'`

### pb_accept_pick
- 역할: '한도를 넘은 것' 줄들("함수<탭>이유들")과 선택 창의 질문 · 답에서 사용자가 받아들인 줄만 낸다 — 질문에 [재는 검사] 와 그 함수 이름이 있고 답이 "이대로"로 시작할 때
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'f\ttime=1.35\ng\tcalls=1:2' "[재는 검사] f — 시간 1.35배. 어떻게 할까요?" "이대로 둠" → $'f\ttime=1.35'`
- 예: `$'f\ttime=1.35' "[재는 검사] f — 시간 1.35배" "고침 (추천)" → ""`
- 예: `$'f\ttime=1.35' "다른 질문 f" "이대로 둠" → ""`

### pb_baseline_next
- 역할: '입력이 커지면 위험한 함수' 기준 목록(이름 줄들)과 지금 한도를 넘는 이름들에서 새 목록을 낸다 — 줄어든 이름은 내리고, 새로 넘는 이름은 "@@new 이름" 줄로 알린다(목록에는 넣지 않는다)
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'a\nb' $'a\nb' → $'a\nb'`
- 예: `$'a\nb' $'a' → "a"`
- 예: `$'a\nb' $'a\nb\nc' → $'a\nb\n@@new c'`

### pb_callers
- 역할: 엮은 함수 줄들("함수<탭>부르는 함수들")에서, 주어진 이름들 가운데 하나라도 부르는 엮은 함수의 이름을 낸다
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'f\tg h\nk\tx y' $'h\nz' → "f"`
- 예: `$'f\tg h' $'q' → ""`

### pb_composed
- 역할: "함수<탭>부르는 함수들" 줄들에서 다른 사전 함수를 N개(기본 2) 이상 부르는 줄만 낸다 — 엮은 함수
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'f\tg h\nk\tg' → $'f\tg h'`
- 예: `$'f\tg h\nk\tg' 1 → $'f\tg h\nk\tg'`

### pc_allowed_filter
- 역할: 짝 목록에서 예외 목록에 이유와 함께 적힌 짝을 빼고, 이유 없는 예외는 따로 표시한다
- 위치: scripts/lib/pure-catalog.sh · @pure · sh
- 예: `$'a\tb\nc\td' $'b\ta\t줄바꿈 처리가 다름' → $'c\td'`
- 예: `$'a\tb' $'a\tb\t' → $'!이유없음\ta\tb\na\tb'`

### pc_duplicate_pairs
- 역할: '지문<탭>함수' 줄들에서 지문이 같은 함수 짝을 들어온 순서대로 낸다
- 위치: scripts/lib/pure-catalog.sh · @pure · sh
- 예: `$'k1\tb\nk2\tc\nk1\ta' → $'b\ta'`
- 예: `$'k1\ta\nk2\tb' → ""`

### pc_mutual_pairs
- 역할: 방향 있는 '가<탭>나' 줄들에서 양쪽 방향이 다 있는 짝만 한 번씩 낸다
- 위치: scripts/lib/pure-catalog.sh · @pure · sh
- 예: `$'a\tb\na\tc\nb\ta' → $'a\tb'`
- 예: `$'a\tb' → ""`

### pc_oversize_files
- 역할: 사전 파일 글들에서 줄 수가 한도를 넘는 파일 이름과 줄 수를 낸다
- 위치: scripts/lib/pure-catalog.sh · @deterministic · sh
- 예: `$'@@FILE a.md\n1\n2\n3\n@@FILE b.md\n1' "2" → $'a.md\t3'`

### pc_text_duplicates
- 역할: 항목들의 예시를 글로 비교해, 같은 입력에 같은 출력인 예시를 공유하고 어긋남이 없는 함수 짝을 같은 언어(same) · 다른 언어(cross) 표시와 함께 낸다
- 위치: scripts/lib/pure-catalog.sh · @deterministic · sh
- 예: `$'a.ts\tpure\tfmt\tr\t변환\t"2026-01-02" → "26/01/02"\nb.py\tpure\tfmt_date\tr\t변환\t"2026-01-02" → "26/01/02"' → $'fmt\tfmt_date\tcross'`
- 예: `$'a.ts\tpure\tf\tr\t다듬기\t" a " → "a"\nb.ts\tpure\tg\tr\t다듬기\t" a " → "a"\x1f"b " → "B"\nc.rs\tpure\th\tr\t다듬기\t"b " → "b"' → $'f\tg\tsame'`

### record_index_filter
- 역할: 색인 텍스트에서 종류가 맞는 레코드만, 키마다 최신 하나씩 남긴다(종류를 비우면 전체)
- 위치: scripts/lib/record-index.sh · @pure · sh
- 예: `$'decision\tk1\tf\t0\t5\tt\ts1\nplan\tk2\tf\t5\t5\tt\ts2' plan → $'plan\tk2\tf\t5\t5\tt\ts2'`

### record_index_lookup
- 역할: 색인 텍스트에서 키가 같은 레코드를 낸다 — 같은 키가 여럿이면 마지막 것
- 위치: scripts/lib/record-index.sh · @pure · sh
- 예: `$'decision\tk1\tf.md\t0\t5\tt\ts1\ndecision\tk1\tf.md\t5\t5\tt\ts2' k1 → $'decision\tk1\tf.md\t5\t5\tt\ts2'`

### scv_as_drop_weak
- 역할: 점수 매긴 줄들에서 두 낱말 이상 맞은 줄이 있으면 하나만 맞은 줄을 버린다
- 위치: scripts/lib/archive-search.sh · @deterministic · sh
- 예: `$'2\x1fg1\x1f계획\x1f1\x1fa\n1\x1fg2\x1f결정\x1f2\x1fb' → $'2\x1fg1\x1f계획\x1f1\x1fa'`
- 예: `$'1\x1fg2\x1f결정\x1f2\x1fb' → $'1\x1fg2\x1f결정\x1f2\x1fb'`

### scv_as_group_best
- 역할: 점수 매긴 줄들에서 묶음마다 가장 높은 점수 줄 하나만 남기고 점수 내림차순으로 낸다
- 위치: scripts/lib/archive-search.sh · @deterministic · sh
- 예: `$'1\x1fg1\x1f계획\x1f1\x1fa\n3\x1fg1\x1f계획\x1f2\x1fb\n2\x1fg2\x1f결정\x1f3\x1fc' → $'3\x1fg1\x1f계획\x1f2\x1fb\n2\x1fg2\x1f결정\x1f3\x1fc'`

### scv_as_score_lines
- 역할: 훑은 "파일:줄번호:내용" 줄들에 낱말 맞은 수 점수를 매겨 점수 US 묶음 US 종류 US 줄번호 US 대목 줄로 낸다
- 위치: scripts/lib/archive-search.sh · @deterministic · sh
- 예: `$'scv/DECISIONS.md:3:login bug fixed' $'login\nbug' → $'2\x1fDECISIONS\x1f결정\x1f3\x1flogin bug fixed'`

### scv_deck_source_dir
- 역할: 코어 루트와 설정 값으로 덱 엔진 폴더 경로를 정한다 — 절대 경로나 .. 이 든 설정 값은 거절(2)
- 위치: scripts/lib/deck-source.sh · @pure · sh
- 예: `/core '' no → "/core/DeckUI"`
- 예: `/core '' yes → "/core/DeckUI"`
- 예: `/core sub/dir no → "/core/sub/dir"`
- 예: `/core ../x no → "" [2]`

### scv_dreams_evidence
- 역할: 개선점 줄들이 가리킨 턴 id 의 사람 메시지를 가려 근거 줄(개선점 번호, 발췌)로 고른다
- 위치: scripts/lib/dreams.sh · @deterministic · sh
- 예: `$'finish\t1\t3\t\ts1/1 s1/2' $'s1\t1\t2026-10-01T01:00:00Z\tfix it\ns1\t2\t2026-10-02T01:00:00Z\tdo more' → $'1\tfix it\n1\tdo more'`

### scv_force_refresh_note
- 역할: 표준입력 점검 stderr 에서 템플릿 자동 갱신에 관한 줄(과 뒤따르는 DIRTY/WARN 줄)만 남긴다
- 위치: scripts/lib/force-help.sh · @pure · sh
- 예: `<<< $'scv: template updated to 0.2.0\n  WARN a.md\nscv: settings created' → $'scv: template updated to 0.2.0\n  WARN a.md'`
- 예: `<<< $'unrelated line' → ""`

### scv_graph_god_nodes
- 역할: 그래프 JSON 에서 연결(차수)이 많은 노드 id 를 상위 n 개(기본 10) 한 줄씩 낸다 (동률은 id 순, jq 필요)
- 위치: scripts/lib/graph.sh · @deterministic · sh
- 예: `'{"nodes":[{"id":"a"},{"id":"b"},{"id":"c"}],"links":[{"source":"a","target":"b"},{"source":"a","target":"c"}]}' 2 → $'a\nb'`

### scv_mp_effort_from_log
- 역할: 세션 기록에서 뽑은 줄들("키":"값" 꼴)에서 마지막 값을 꺼내 effort 낱말이면 낸다(없으면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'"k":"low"\n"k":"high"' "k" → "high"`
- 예: `'"k":"banana"' "k" → ""`
- 예: `'"a":"low"' "k" → ""`
- 예: `'"k":"low"' "" → ""`

### scv_mp_effort_row
- 역할: 권장 effort 표에서 이 모델의 줄을 골라 "권장<TAB>조건<TAB>근거<TAB>출처" 로 낸다(줄이 없거나 값 낱말이 틀리면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'# c\nm-a\thigh\t-\tStart at high.\ta.md' "m-a" → $'high\t-\tStart at high.\ta.md'`
- 예: `$'m-a\thigh\t-\tStart at high.\ta.md' "m-b" → ""`
- 예: `$'m-a\tfast\t-\tx\ta.md' "m-a" → ""`

### scv_mp_effort_state_of
- 역할: 물은 조건 파일 글에서 이 조건의 상태를 꺼낸다 — asked(물었다) · shown:N(줄을 N번 실었다) · 빈 값(처음)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'m|high|medium|shown:2\nx|low|high|asked' "m|high|medium" → "shown:2"`
- 예: `$'x|low|high|asked' "x|low|high" → "asked"`
- 예: `"m|high|medium" "m|high|medium" → "asked"`
- 예: `"" "m|high|medium" → ""`

### scv_mp_warn_keep
- 역할: 경고 파일에서 "[SCV 가이드]" 줄과 그 뒤 두 칸 들여 쓴 줄만 남긴다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'[SCV 가이드] a\n  detail\nother' → $'[SCV 가이드] a\n  detail\n'`

### scv_pd_lang
- 역할: 파일 이름의 확장자로 함수 찾기 규칙(언어)을 고른다 — 모르는 확장자는 빈 값
- 위치: scripts/lib/pure-declare.sh · @pure · sh
- 예: `src/a.ts → "js"`
- 예: `lib/x.sh → "sh"`
- 예: `app/m.py → "py"`
- 예: `README.md → ""`

### scv_pr_base_branch
- 역할: PR 대상 브랜치를 정한다 — 에픽 > 설정 값 > origin 기본 브랜치 > main 순
- 위치: scripts/lib/pr-flow.sh · @pure · sh
- 예: `'' develop main → "develop"`
- 예: `e1 develop main → "epic/e1"`
- 예: `'' '' '' → "main"`

### scv_pr_stray_changes
- 역할: git 상태 기록에서 허용 경로 밖의 변경 경로만 줄마다 하나 낸다(끝이 / 인 허용 경로는 폴더)
- 위치: scripts/lib/pr-flow.sh · @pure · sh
- 예: `$' M scv/a.md\n M src/x.sh' $'scv/' → "src/x.sh"`

### scv_rc_allowed_out
- 역할: 후보 키에서 허용목록에 있는 키를 뺀 나머지를 낸다
- 위치: scripts/lib/rule-constitution.sh · @pure · sh
- 예: `$'k1\nk2\nk3' $'k2' → $'k1\nk3'`

### scv_rc_duplicate_keys
- 역할: 표준입력 "키 파일" 줄에서 두 파일 이상에 나온 키만 정렬해 낸다
- 위치: scripts/lib/rule-constitution.sh · @deterministic · sh
- 예: `<<< $'k1\ta.md\nk1\tb.md\nk2\ta.md' → "k1"`

### scv_rc_normative_rows
- 역할: 표준입력 "파일 줄번호 본문" 표에서 규범 동사가 든 줄만 남긴다
- 위치: scripts/lib/rule-constitution.sh · @pure · sh
- 예: `<<< $'a.md\t1\tYou must test\na.md\t2\tNice day' → $'a.md\t1\tYou must test'`

### scv_rc_precedence_violations
- 역할: 우선순위 어휘를 담은 줄 중 참조형 · 허용 구간 · 허용목록 밖의 것을 그대로 낸다
- 위치: scripts/lib/rule-constitution.sh · @pure · sh
- 예: `$'a.md\t3\tThis overrides everything' a.md 10 20 '' → $'a.md\t3\tThis overrides everything'`
- 예: `$'a.md\t15\tThis overrides everything' a.md 10 20 '' → ""`
- 예: `$'a.md\t3\tThis overrides everything\nb.md\t4\tSee Top-level rules, which win over this' a.md 10 20 '' → $'a.md\t3\tThis overrides everything'`

### scv_reg_collect_keys
- 역할: 여러 블록의 줄에서 시험 줄 키를 처음 나온 순서대로 겹치지 않게 모은다
- 위치: scripts/lib/regression-memo.sh · @pure · sh
- 예: `$'bash t/a.sh\necho x\n  bash t/a.sh >/dev/null\nbash t/b.sh' → $'bash t/a.sh\nbash t/b.sh'`
- 예: `"bash t/a.sh && bash t/c.sh" → $'bash t/a.sh\nbash t/c.sh'`
- 예: `"echo x" → ""`

### scv_resume_other_active
- 역할: 고른 경로를 뺀 나머지 active 경로들을 한 줄씩 낸다
- 위치: scripts/lib/resume-recap.sh · @pure · sh
- 예: `$'a.md\tactive\t5\nb.md\tactive\t9' b.md → "a.md"`

### scv_resume_pick_active
- 역할: "경로 status mtime" 줄들 중 active 이고 mtime 이 가장 큰 경로 하나를 고른다(동률이면 뒤 줄)
- 위치: scripts/lib/resume-recap.sh · @pure · sh
- 예: `$'a.md\tactive\t5\nb.md\tactive\t9\nc.md\tdone\t99' → "b.md"`

### scv_show_real_lookup
- 역할: 열쇠 붙은 발췌 줄마다 저장된 답이 있으면 A 줄, 없으면 물을 턴 Q 줄로 나눠 낸다
- 위치: scripts/lib/show-real.sh · @deterministic · sh
- 예: `$'k1\ts1\tt\tb\tx\nk2\ts2\tt\ta\ty' $'k1\tyes' → $'A\tk1\ts1\tt\tb\tyes\nQ\tk2\ts2\tt\ta\ty'`

### scv_show_real_pick
- 역할: 사람 턴 줄들에서 두 기간 안에서 출력을 보였으나 묻지 않은 애매한 턴만 골라 낸다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `$'s1\t2026-10-01T01:00:00Z\tERTq\tfix it\tdone\tAll 5 passed.\t5 passed' 540 "20261001 20261001" "" → $'s1\t2026-10-01T01:00:00Z\tb\t5 passed\tAll 5 passed.'`
- 예: `$'s1\t2026-10-01T01:00:00Z\tERTq\tfix it\tdone\tAll 5 passed.\t5 passed' 540 "" "" → ""`

### scv_step_active_plan
- 역할: "계획<TAB>상태" 줄들 중 구현 중(in_progress · testing)인 계획 이름 하나를 고른다 — 여럿이면 마지막 줄(줄은 이름순으로 받는다 — 날짜가 앞이라 가장 최근)
- 위치: scripts/lib/step-report.sh · @pure · sh
- 예: `$'20260101-a-x\tplanned\n20260102-a-y\tin_progress' → "20260102-a-y"`
- 예: `$'20260101-a-x\ttesting\n20260103-a-z\tin_progress' → "20260103-a-z"`
- 예: `$'20260101-a-x\tplanned' → ""`

### scv_stop_pick_source
- 역할: 호스트가 넘긴 답을 먼저, 없으면 원본의 이번 턴 텍스트를 골라 "출처\x1f본문" 으로 낸다 (둘 다 없으면 none)
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `"host text" "turn text" → $'host\x1fhost text'`
- 예: `"" "" → $'none\x1f'`

### scv_tc_filter
- 역할: 바뀐 경로 목록에서 SCV 기록 폴더 · graft 그래프와 호스트가 알려 준 설정 경로(: 로 이은 글롭)를 뺀다 — 계획 · 저널 · 대화는 '일'이 아니다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `$'scv/promote/a/PLAN.md\nsrc/a.ts\nhost/settings.json\nREADME.md' "host/settings.json" → $'src/a.ts\nREADME.md'`
- 예: `$'graft/x.md\n.scv-pr-artifacts/a.png\nconf/a.toml' "conf/*" → ""`
- 예: `"" "" → ""`

### scv_tc_mine_only
- 역할: 경로 줄들 중 '이 세션이 쓴 파일' 목록에 있는 것만 남긴다 — 다른 세션이 같은 폴더에서 고친 파일을 뺀다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `$'/r/a\n/r/b' $'/r/b\n/x/c' → "/r/b"`
- 예: `"/r/a" "" → ""`

### scv_writing_over_limit
- 역할: 줄들 중 글자 수가 한도를 넘는 줄을 "글자수<탭>줄" 로 고른다
- 위치: scripts/lib/writing.sh · @pure · sh
- 예: `$'ab\nabcdefgh' 5 → $'8\tabcdefgh'`
- 예: `"abc" 3 → ""`
- 예: `"" 10 → ""`

### scv_writing_vague_criteria
- 역할: 통과 기준 줄 중 값 · 정확한 문구가 하나도 없는 줄(숫자 · 백틱 · 따옴표가 없음)을 고른다
- 위치: scripts/lib/writing.sh · @pure · sh
- 예: `$'잘 동작한다\n종료 코드 0' → "잘 동작한다"`
- 예: `$'`OK readme` 출력\n"완료" 문구' → ""`
- 예: `"" → ""`

### settings_resolve
- 역할: 환경변수 · 설정 파일 · 프로젝트 · 기본값 중 앞에서부터 처음 값이 있는 것을 고른다
- 위치: scripts/lib/settings.sh · @pure · sh
- 예: `env '' proj def → "env"`
- 예: `'' set '' def → "set"`
- 예: `'' '' '' def → "def"`
