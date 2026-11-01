# 판정 — 입력을 보고 예/아니오나 판정 이름 하나를 낸다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 22개.

### pc_validate_entries
- 역할: 항목마다 빠진 칸(역할 · 종류 · 예)과 종류 표에 없는 종류를 위반 줄로 낸다
- 위치: scripts/lib/pure-catalog.sh · @pure
- 예: `$'a.sh\tpure\tf\t\t세기\tx' $'세기\tcount\t센다' → $'f\ta.sh\t역할 없음'`
- 예: `$'a.sh\tpure\tf\t센다\t뭐\tx' $'세기\tcount\t센다' → $'f\ta.sh\t모르는 종류: 뭐'`
- 예: `$'a.sh\tpure\tf\t센다\t세기/json\tx' $'세기\tcount\t센다' → ""`

### scv_delegate_switch
- 역할: 위임 스위치 값을 해석한다 — on 만 켜고 나머지는 모두 off
- 위치: scripts/lib/force-help.sh · @pure
- 예: `on → "on"`
- 예: `'' → "off"`
- 예: `maybe → "off"`
- 예: `' "ON" ' → "on"`

### scv_dreams_tip_rule
- 역할: 개선점 줄의 종류로 판정자에게 권할 가이드 규칙 이름(finish · depth · goal)을 낸다
- 위치: scripts/lib/dreams.sh · @pure
- 예: `$'finish\t1\t3\t\t' → 'finish'`
- 예: `$'correction\t2\t5\t\t' → 'goal'`

### scv_dreams_tips
- 역할: 등록 · 사람 턴 · 분포 줄들에서 개선점 줄(finish · depth · correction · plan)이 필요한지 가려 낸다
- 위치: scripts/lib/dreams.sh · @pure
- 예: `$'s1\t1\tt\t-\t-\tasked\ns1\t2\tt\t-\t-\tasked\ns1\t3\tt\t-\t-\tasked'   → $'finish\t0\t3\t\ts1/1 s1/2 s1/3\ndepth\t0\t3\t\ts1/1 s1/2 s1/3'`

### scv_dreams_unit
- 역할: 사람 턴 수로 기간 단위를 정한다(100턴 이상이면 dekad, 아니면 month)
- 위치: scripts/lib/dreams.sh · @pure
- 예: `100 → 'dekad'`
- 예: `5 → 'month'`

### scv_graft_status
- 역할: graft 실행 파일 · 그래프 유무와 스위치로 absent · no-graph · ready · off 중 하나를 낸다
- 위치: scripts/lib/graft.sh · @pure
- 예: `0 0 auto → "absent"`
- 예: `1 0 auto → "no-graph"`
- 예: `1 1 auto → "ready"`
- 예: `1 1 off → "off"`

### scv_graph_is_path
- 역할: 토큰이 저장소 상대 파일 경로처럼 보이는지 판정한다 (URL · 절대 경로 · 글롭 · 확장자 없음 · 버전 번호는 아님; 두 번째 인자 1 이면 슬래시 필요)
- 위치: scripts/lib/graph.sh · @pure
- 예: `"core/scripts/x.sh" 1 → ""`
- 예: `"x.sh" 1 → [1]`
- 예: `"http://a/b.md" 0 → [1]`
- 예: `"v1.2" 0 → [1]`

### scv_graph_status_of
- 역할: 그래프 존재 여부와 파일 시각으로 missing | stale | built 중 하나를 정한다
- 위치: scripts/lib/graph.sh · @pure
- 예: `0 0 0 → "missing"`
- 예: `1 5 10 → "stale"`
- 예: `1 10 10 → "built"`

### scv_hstate_diag
- 역할: 진단 본문의 해시를 직전과 견줘 "full"(바뀜) 또는 "brief"(같음)와 새 상태를 \x1f 로 이어 낸다
- 위치: scripts/lib/help-state.sh · @deterministic
- 예: `$'s1\x1f1\x1f3\x1f\x1f\x1f' "diag text" 09:30 → $'full\x1fs1\x1f1\x1f3\x1f99c262b5b4fbdc2a\x1f09:30\x1f'`

### scv_hstate_protocol_line
- 역할: 상태와 스위치로 "PROTOCOL: load"(읽어라) 또는 "PROTOCOL: loaded"(이미 읽음)를 정한다
- 위치: scripts/lib/help-state.sh · @pure
- 예: `$'s1\x1f1\x1f3' on → "PROTOCOL: loaded"`
- 예: `$'s1\x1f1\x1f3' off → "PROTOCOL: load"`

### scv_mp_safe_name
- 역할: 색인 폴더 안의 평범한 파일 이름이면 그대로, 경로 · 점 시작 · ".." 이면 빈 값을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `"guide-1.md" → "guide-1.md"`
- 예: `"../x" → ""`

### scv_mp_session_key
- 역할: 세션 id 가 폴더 이름으로 안전하면 그대로, 아니면 빈 값을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `"sess-1" → "sess-1"`
- 예: `"a/b" → ""`
- 예: `"a..b" → "a..b"`

### scv_mp_switch
- 역할: 스위치 값을 on|off 로 정한다(기본 on, "off" 만 끈다)
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `" OFF " → "off"`
- 예: `"" → "on"`
- 예: `yes → "on"`
- 예: `"off[1m]" → "off"`

### scv_mp_turn_dir_ok
- 역할: 넘겨받은 폴더가 저널 폴더나 그 아래 세션 폴더면 그대로, 아니면 저널 폴더를 낸다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `scv/journal scv/journal/.help-turns/s1 → "scv/journal/.help-turns/s1"`
- 예: `scv/journal /etc → "scv/journal"`

### scv_mp_was_read
- 역할: 이 컨텍스트에서 그 모델 원문을 이미 읽었는지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `$'n\x1fm\x1fload\x1fk' $'n\x1fm' cur → "1"`
- 예: `$'n\x1fm\x1fload\x1fk' $'z\x1fm' cur → "0"`
- 예: `$'n\x1fm\x1fload\x1fk' $'cur\x1fm' cur → "1"`

### scv_mx_metric_followup
- 역할: 색인의 slug 마다 후속 계획이 있으면 1, 없으면 0 을 낸다 (obsoleted_by 대상 또는 supersedes 보유)
- 위치: scripts/lib/metrics.sh · @pure
- 예: `$'a\tx\tb\nb\tx\t\n' "" → $'a\t0\nb\t1'`

### scv_privacy_email_ok
- 역할: 공개해도 되는 메일 주소(GitHub noreply · 봇)면 참
- 위치: scripts/lib/privacy.sh · @pure
- 예: `1+a@users.noreply.github.com → ""`
- 예: `noreply@anthropic.com → ""`
- 예: `me@gmail.com → "" [1]`

### scv_reg_is_core_loop
- 역할: '코어 시험 전부' 반복 줄(for t in core/tests/test-*.sh …)이면 1 을 낸다 — 시험 파일 하나하나로 나눠 공유할 수 있다
- 위치: scripts/lib/regression-memo.sh · @pure
- 예: `'for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "T $t"; done' → [0]`
- 예: `"bash core/tests/test-a.sh" → [1]`

### scv_show_real_channel
- 역할: 쓸 수 있는 선택 창과 실행 상태로 질문 통로(choice · text · none)를 정한다
- 위치: scripts/lib/show-real.sh · @pure
- 예: `"ChoiceTool" 0 human → $'choice'`
- 예: `"" 0 human → 'text'`
- 예: `"ChoiceTool" 1 human → $'none'`

### scv_show_real_valid_day
- 역할: 연 · 월 · 일이 있는 날인지(윤년 포함) 1 또는 0 으로 낸다
- 위치: scripts/lib/show-real.sh · @pure
- 예: `2026 02 30 → '0'`
- 예: `2028 02 29 → '1'`

### scv_switch
- 역할: 설정 값을 on|off 로 정한다 — off 만 끄고(대소문자 · 공백 · 따옴표 무관) 비었거나 다른 값은 on
- 위치: scripts/lib/switch.sh · @pure
- 예: `' "OFF" ' → "off"`
- 예: `"" → "on"`
- 예: `maybe → "on"`

### settings_is_secret
- 역할: 설정 키가 비밀 키 목록(토큰 등)에 있으면 참
- 위치: scripts/lib/settings.sh · @pure
- 예: `SLACK_BOT_TOKEN → ""`
- 예: `SCV_LANG → "" [1]`
- 예: `'' → "" [1]`
