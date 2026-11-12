# 판정 — 입력을 보고 예/아니오나 판정 이름 하나를 낸다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 45개.

### pb_accept_covers
- 역할: 사용자가 받아들인 이유들과 지금의 이유들을 견줘, 지금 것이 모두 받아들인 범위 안이면 참 — 시간 · 배수는 받아들인 값의 2배까지, 메모리는 1.2배까지, 부른 횟수는 받아들인 수까지
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `"time=1.35" "time=1.40" → ""`
- 예: `"time=1.35" "time=3.00" → "" [1]`
- 예: `"mem=1.9:37.0" "mem=1.9:50.0" → "" [1]`
- 예: `"time=1.35" "time=1.30 calls=1:2" → "" [1]`
- 예: `"calls=1:100 mem=1.9:37.0" "calls=1:100" → ""`

### pb_compare
- 역할: 한 함수의 앞뒤 잰 줄("함수<탭>상태<탭>잣대<탭>앞 값<탭>뒤 값<탭>부른 횟수 앞<탭>뒤<탭>메모리 앞<탭>뒤<탭>4배 배수 앞<탭>뒤")을 한도로 가려 "함수<탭>판정<탭>이유들"을 낸다 — 판정: pass | fail | new | skipped-different-answer | unmeasured | not-reached
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'f\tok\tcpu\t3.000\t3.450\t0\t0\t2.4\t2.5\t-\t-' → $'f\tpass\t-'`
- 예: `$'f\tok\tcpu\t3.000\t3.750\t0\t0\t2.4\t2.5\t-\t-' → $'f\tfail\ttime=1.25'`
- 예: `$'f\tok\tcpu\t3.000\t3.000\t1\t2\t8.0\t10.0\t4.0\t9.1' → $'f\tfail\tcalls=1:2 mem=8.0:10.0 scale=4.0:9.1'`
- 예: `$'f\tok\tcpu\t3.000\t3.000\t0\t0\t1.2\t1.5\t9.0\t9.5' → $'f\tpass\t-'`
- 예: `$'f\tdifferent-answer\t-\t-\t-\t-\t-\t-\t-\t-\t-' → $'f\tskipped-different-answer\t-'`
- 예: `$'f\tok\tcpu\t3.000\t3.000\t0\t0\t2.4\t2.5\ttoo-slow\t9.1' → $'f\tpass\t-'`
- 예: `$'f\tok\tcpu\t3.000\t3.000\t0\t0\t2.4\t2.5\t4.0\ttoo-slow' → $'f\tfail\tscale=4.0:too-slow'`
- 예: `$'f\tok\tcpu\ttoo-slow\t3.000\t0\t0\t-\t2.5\ttoo-slow\ttoo-slow' → $'f\tpass\t-'`

### pb_pairs_enough
- 역할: 번갈아 잰 앞 값들과 뒤 값들에서, 마지막 두 쌍이 모두 "뒤가 앞의 절반 이하"이면 1 을 낸다 — 뚜렷이 빨라진 함수는 남은 쌍을 재지 않아도 된다
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `"100.0 98.0" "10.0 12.0" → "1"`
- 예: `"100.0 98.0" "10.0 60.0" → "0"`
- 예: `"100.0" "10.0" → "0"`
- 예: `"30.0 100.0 98.0" "29.0 10.0 12.0" → "1"`
- 예: `"100.0 -" "10.0 12.0" → "0"`

### pb_pick_measure
- 역할: 잰 값(벽시계 · CPU 초 · GPU 메모리 증가 · GPU 사용률 오름)과 컴퓨터의 붐빔(100 = 한가함)을 보고 판정 잣대 이름을 낸다 — cpu | wall-gpu | unmeasured
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `1.00 0.98 0.0 4 100 → "cpu"`
- 예: `8.40 0.80 1171.0 78 100 → "wall-gpu"`
- 예: `8.40 0.80 - - 100 → "unmeasured"`
- 예: `0.01 0.00 - - 100 → "unmeasured"`
- 예: `2.00 0.98 0.0 4 210 → "cpu"`

### pb_scale_over
- 역할: 4배 배수 값이 한도(8배)를 넘거나 한도 시간에 끊긴 값(too-slow)이면 1 을 낸다 — 뒤 값이 이럴 때만 앞의 4배 값이 판정에 쓰인다
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `9.1 → "1"`
- 예: `8.0 → "0"`
- 예: `too-slow → "1"`
- 예: `- → "0"`

### pc_validate_entries
- 역할: 항목마다 빠진 칸(역할 · 종류 · 예)과 종류 표에 없는 종류를 위반 줄로 낸다
- 위치: scripts/lib/pure-catalog.sh · @pure · sh
- 예: `$'a.sh\tpure\tf\t\t세기\tx' $'세기\tcount\t센다' → $'f\ta.sh\t역할 없음'`
- 예: `$'a.sh\tpure\tf\t센다\t뭐\tx' $'세기\tcount\t센다' → $'f\ta.sh\t모르는 종류: 뭐'`
- 예: `$'a.sh\tpure\tf\t센다\t세기/json\tx' $'세기\tcount\t센다' → ""`

### scv_delegate_switch
- 역할: 위임 스위치 값을 해석한다 — on 만 켜고 나머지는 모두 off
- 위치: scripts/lib/force-help.sh · @pure · sh
- 예: `on → "on"`
- 예: `'' → "off"`
- 예: `maybe → "off"`
- 예: `' "ON" ' → "on"`

### scv_dreams_tip_rule
- 역할: 개선점 줄의 종류로 판정자에게 권할 가이드 규칙 이름(finish · depth · goal)을 낸다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'finish\t1\t3\t\t' → 'finish'`
- 예: `$'correction\t2\t5\t\t' → 'goal'`

### scv_dreams_tips
- 역할: 등록 · 사람 턴 · 분포 줄들에서 개선점 줄(finish · depth · correction · plan)이 필요한지 가려 낸다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'s1\t1\tt\t-\t-\tasked\ns1\t2\tt\t-\t-\tasked\ns1\t3\tt\t-\t-\tasked'   → $'finish\t0\t3\t\ts1/1 s1/2 s1/3\ndepth\t0\t3\t\ts1/1 s1/2 s1/3'`

### scv_dreams_unit
- 역할: 사람 턴 수로 기간 단위를 정한다(100턴 이상이면 dekad, 아니면 month)
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `100 → 'dekad'`
- 예: `5 → 'month'`

### scv_graft_status
- 역할: graft 실행 파일 · 그래프 유무와 스위치로 absent · no-graph · ready · off 중 하나를 낸다
- 위치: scripts/lib/graft.sh · @pure · sh
- 예: `0 0 auto → "absent"`
- 예: `1 0 auto → "no-graph"`
- 예: `1 1 auto → "ready"`
- 예: `1 1 off → "off"`

### scv_graph_is_path
- 역할: 토큰이 저장소 상대 파일 경로처럼 보이는지 판정한다 (URL · 절대 경로 · 글롭 · 확장자 없음 · 버전 번호는 아님; 두 번째 인자 1 이면 슬래시 필요)
- 위치: scripts/lib/graph.sh · @pure · sh
- 예: `"core/scripts/x.sh" 1 → ""`
- 예: `"x.sh" 1 → [1]`
- 예: `"http://a/b.md" 0 → [1]`
- 예: `"v1.2" 0 → [1]`

### scv_graph_status_of
- 역할: 그래프 존재 여부와 파일 시각으로 missing | stale | built 중 하나를 정한다
- 위치: scripts/lib/graph.sh · @pure · sh
- 예: `0 0 0 → "missing"`
- 예: `1 5 10 → "stale"`
- 예: `1 10 10 → "built"`

### scv_hstate_diag
- 역할: 진단 본문의 해시를 직전과 견줘 "full"(바뀜) 또는 "brief"(같음)와 새 상태를 \x1f 로 이어 낸다
- 위치: scripts/lib/help-state.sh · @deterministic · sh
- 예: `$'s1\x1f1\x1f3\x1f\x1f\x1f' "diag text" 09:30 → $'full\x1fs1\x1f1\x1f3\x1f99c262b5b4fbdc2a\x1f09:30\x1f'`

### scv_hstate_protocol_line
- 역할: 상태와 스위치로 "PROTOCOL: load"(읽어라) 또는 "PROTOCOL: loaded"(이미 읽음)를 정한다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `$'s1\x1f1\x1f3' on → "PROTOCOL: loaded"`
- 예: `$'s1\x1f1\x1f3' off → "PROTOCOL: load"`

### scv_mp_effort_asked_in
- 역할: 그 턴에 effort 를 실제로 물었는지 가린다 — 선택 창 질문 글에 effort 가 있거나, 답 글에 effort · 지금 값 · 권장 값 · 물음표가 함께 있으면 1
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"" "effort 를 high 로 바꾸시겠어요?" medium high → "1"`
- 예: `"effort 는 low 인데 권장은 high. high 로 바꿀까요, low 그대로 둘까요?" "" low high → "1"`
- 예: `"effort 를 high 로 올렸습니다." "" low high → "0"`
- 예: `"파일은 한 줄입니다." "" low high → "0"`

### scv_mp_effort_verdict
- 역할: effort 를 물을지 정한다 — off(꺼짐) · unknown(값이나 표를 모름) · same(권장과 같음) · asked(물었거나 세 번 실었다) · ask
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `on high $'medium\t-\tq\ts' "" m → "ask"`
- 예: `on high $'medium\t-\tq\ts' "asked" m → "asked"`
- 예: `on high $'medium\t-\tq\ts' "shown:2" m → "ask"`
- 예: `on high $'medium\t-\tq\ts' "shown:3" m → "asked"`
- 예: `on medium $'medium\t-\tq\ts' "" m → "same"`
- 예: `on "" $'medium\t-\tq\ts' "" m → "unknown"`
- 예: `on high "" "" m → "unknown"`
- 예: `off high $'medium\t-\tq\ts' "" m → "off"`

### scv_mp_effort_word
- 역할: effort 값 낱말이 맞는지 가려, 맞으면 소문자로 낸다(아니면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"High" → "high"`
- 예: `"banana" → ""`
- 예: `"" → ""`

### scv_mp_has_guides
- 역할: 색인에 가이드 행(모델 행이나 공통 행)이 하나라도 있는지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'# c\n@holder\tX\n*\tcommon\tc.md\tu\t2026-01-01' → "1"`
- 예: `$'# c\n@holder\tX' → "0"`

### scv_mp_read_name
- 역할: 가이드 원문 이름과 그 발췌본이 있는지로, help 가 읽게 할 파일 이름을 고른다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `best-practices.md 1 → "excerpt-best-practices.md"`
- 예: `best-practices.md 0 → "best-practices.md"`

### scv_mp_safe_name
- 역할: 색인 폴더 안의 평범한 파일 이름이면 그대로, 경로 · 점 시작 · ".." 이면 빈 값을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"guide-1.md" → "guide-1.md"`
- 예: `"../x" → ""`

### scv_mp_session_key
- 역할: 세션 id 가 폴더 이름으로 안전하면 그대로, 아니면 빈 값을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"sess-1" → "sess-1"`
- 예: `"a/b" → ""`
- 예: `"a..b" → "a..b"`

### scv_mp_switch
- 역할: 스위치 값을 on|off 로 정한다(기본 on, "off" 만 끈다)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `" OFF " → "off"`
- 예: `"" → "on"`
- 예: `yes → "on"`
- 예: `"off[1m]" → "off"`

### scv_mp_turn_dir_ok
- 역할: 넘겨받은 폴더가 저널 폴더나 그 아래 세션 폴더면 그대로, 아니면 저널 폴더를 낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `scv/journal scv/journal/.help-turns/s1 → "scv/journal/.help-turns/s1"`
- 예: `scv/journal /etc → "scv/journal"`

### scv_mp_was_read
- 역할: 이 컨텍스트에서 그 모델 원문을 이미 읽었는지 1|0 으로 정한다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'n\x1fm\x1fload\x1fk' $'n\x1fm' cur → "1"`
- 예: `$'n\x1fm\x1fload\x1fk' $'z\x1fm' cur → "0"`
- 예: `$'n\x1fm\x1fload\x1fk' $'cur\x1fm' cur → "1"`

### scv_mx_metric_followup
- 역할: 색인의 slug 마다 후속 계획이 있으면 1, 없으면 0 을 낸다 (obsoleted_by 대상 또는 supersedes 보유)
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'a\tx\tb\nb\tx\t\n' "" → $'a\t0\nb\t1'`

### scv_plan_conflict_after
- 역할: 뒤쪽 충돌 검사 — B 가 바꾼 파일 경로가 A 의 끝나지 않은 단계 글에 나오면 "겹침 · A n단계 · 파일" 줄을 낸다
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'## Suggested path\n1. [x] core/a.sh 고침\n2. core/a.sh 와 core/b.sh 손봄' $'core/a.sh\ncore/c.sh' → "겹침 · A 2단계 · core/a.sh"`
- 예: `$'## Suggested path\n1. 문서 고침' "core/a.sh" → ""`
- 예: `$'## Suggested path\n1. a' "" → ""`

### scv_plan_conflict_before
- 역할: 앞쪽 충돌 검사 — B 의 Goals 항목이 A 의 Non-Goals(충돌) 또는 A 의 남은 단계(겹침)와 글자로 겹치는 것을 한 줄씩 낸다
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'## Goals / Non-Goals\n- **Non-Goals**\n  - 결제 한도 변경 안 함' $'## Goals / Non-Goals\n- **Goals**\n  - 결제 한도 변경' → "충돌 · A 가 하지 않기로 함: 결제 한도 변경 안 함 ↔ B 목표: 결제 한도 변경"`
- 예: `$'## Suggested path\n1. [x] 준비\n2. 화면 만들기 — `x`' $'## Goals / Non-Goals\n- **Goals**\n  - 화면 만들기' → $'겹침 · A 2단계: 화면 만들기 — `x` ↔ B 목표: 화면 만들기'`
- 예: `$'## Goals / Non-Goals\n- **Non-Goals**\n  - 가' $'## Goals / Non-Goals\n- **Goals**\n  - 나' → ""`

### scv_plan_fm_has
- 역할: PLAN.md 글의 앞머리에 그 칸이 있으면 "1" 을 낸다 — 값이 비어 있어도 칸이 있으면 "1"
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'---\nstatus: paused\nresume_at:\n---' "resume_at" → "1"`
- 예: `$'---\nstatus: paused\n---' "resume_at" → ""`
- 예: `"# a" "status" → ""`

### scv_privacy_email_ok
- 역할: 공개해도 되는 메일 주소(GitHub noreply · 봇)면 참
- 위치: scripts/lib/privacy.sh · @pure · sh
- 예: `1+a@users.noreply.github.com → ""`
- 예: `noreply@anthropic.com → ""`
- 예: `me@gmail.com → "" [1]`

### scv_reg_is_core_loop
- 역할: '코어 시험 전부' 반복 줄(for t in core/tests/test-*.sh …)이면 1 을 낸다 — 시험 파일 하나하나로 나눠 공유할 수 있다
- 위치: scripts/lib/regression-memo.sh · @pure · sh
- 예: `'for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "T $t"; done' → [0]`
- 예: `"bash core/tests/test-a.sh" → [1]`

### scv_show_real_channel
- 역할: 쓸 수 있는 선택 창과 실행 상태로 질문 통로(choice · text · none)를 정한다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `"ChoiceTool" 0 human → $'choice'`
- 예: `"" 0 human → 'text'`
- 예: `"ChoiceTool" 1 human → $'none'`

### scv_show_real_valid_day
- 역할: 연 · 월 · 일이 있는 날인지(윤년 포함) 1 또는 0 으로 낸다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `2026 02 30 → '0'`
- 예: `2028 02 29 → '1'`

### scv_stop_mode
- 역할: 설정 값으로 종료 검사가 어긋난 답을 어떻게 다룰지(막기 · 다음 턴 안내) 정한다
- 위치: scripts/lib/stop-gates.sh · @pure · sh
- 예: `"" → "notice"`
- 예: `block → "block"`
- 예: `"Block " → "block"`

### scv_switch
- 역할: 설정 값을 on|off 로 정한다 — off 만 끄고(대소문자 · 공백 · 따옴표 무관) 비었거나 다른 값은 on
- 위치: scripts/lib/switch.sh · @pure · sh
- 예: `' "OFF" ' → "off"`
- 예: `"" → "on"`
- 예: `maybe → "on"`

### scv_tc_exempt_ok
- 역할: 계획 없이 해도 되는 정한 예외 종류인지 가린다 — 릴리스 · 동기화만
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"release" → "yes"`
- 예: `"sync" → "yes"`
- 예: `"misc" → "no"`

### scv_tc_nongoal_hits
- 역할: 덧붙이거나 진행으로 적으려는 글에 계획의 '하지 않음'(Non-Goals) 항목 낱말의 절반 이상이 들어 있으면 한 줄씩 낸다 — 겹치면 사용자에게 물을 일
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `$'## Goals / Non-Goals\n- **Goals**\n  - 결제 버튼\n- **Non-Goals**\n  - 환불 기능' "환불 버튼 추가" → "충돌 · 하지 않기로 함: 환불 기능 ↔ 적으려는 글: 환불 버튼 추가"`
- 예: `$'## Goals / Non-Goals\n- **Non-Goals**\n  - 환불 기능' "결제 버튼 색" → ""`
- 예: `$'## Goals / Non-Goals\n- **Non-Goals**\n  - 답 모양 같은 output 규칙의 내용을 바꾸는 일' "시험 파일을 새 모양에 맞춤" → ""`
- 예: `"# a" "x" → ""`

### scv_tc_receipt
- 역할: 도구가 돌린 명령 글이 계획 기록 명령(plan-link 의 기록 다섯 가지)인지 가려 영수증 한 줄을 낸다 — 이름만 적은 명령은 빈 값
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"bash /p/core/scripts/plan-link.sh progress a --step 1 --note x" → "plan-link progress"`
- 예: `$'cd /w && SCV_TODAY=2026-11-09 bash "/p/plan-link.sh" append a --after 1' → "plan-link append"`
- 예: `"echo plan-link.sh append; printf x" → ""`
- 예: `"bash plan-link.sh append a" → ""`

### scv_tc_session_closes
- 역할: 세션 열기의 종류가 앞 턴을 끝난 것으로 만드는지 가린다 — 새로 열기 · 다시 열기만 그렇다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"startup" → "1"`
- 예: `"resume" → "1"`
- 예: `"compact" → "0"`
- 예: `"clear" → "0"`
- 예: `"" → "0"`

### scv_tc_start_mode
- 역할: 사람의 말이 왔을 때 턴 상태를 새로 시작할지 이어 갈지 가린다 — 앞 턴이 끝나지 않았을 때만 이어 간다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `1 0 → "continue"`
- 예: `1 1 → "fresh"`
- 예: `0 0 → "fresh"`
- 예: `0 1 → "fresh"`

### scv_tc_step_on
- 역할: 호스트 설정 글에 대시보드(단계 보고 도구를 주는 모드)가 켜졌다는 표시가 있는지 가린다
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `$'{"enabledPlugins": {"scv-dashboard@scv-mods": true}}' '"scv-dashboard@scv-mods": true' → "yes"`
- 예: `$'{"enabledPlugins": {"scv-dashboard@scv-mods": false}}' '"scv-dashboard@scv-mods": true' → "no"`
- 예: `"x" "" → "no"`

### scv_tc_tool_kind
- 역할: 도구 입력에 어떤 칸이 있는지로 이 도구가 파일을 쓰는지 가른다 — 명령 글이 있으면 shell, 경로와 쓸 내용이 있으면 write, 그 밖(읽기 · 찾기)은 read
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"ls" "" "" → "shell"`
- 예: `"" "/a/b.ts" "yes" → "write"`
- 예: `"" "/a/b.ts" "" → "read"`

### scv_writing_limits
- 역할: README 파일 이름으로 칸 · 문단 길이 한도(글자)를 정한다 — 한글 · 일본어 판은 영어 판의 절반
- 위치: scripts/lib/writing.sh · @pure · sh
- 예: `"README.md" → "60 600"`
- 예: `"README.ko.md" → "40 300"`
- 예: `"docs/README.ja.md" → "40 300"`

### scv_writing_pick_locale
- 역할: 쓸 수 있는 UTF-8 지역 설정 이름 하나를 고른다 — 글자 수를 바이트가 아닌 글자로 세려고
- 위치: scripts/lib/writing.sh · @pure · sh
- 예: `"C.UTF-8 en_US.UTF-8" "en_US.UTF-8" → "en_US.UTF-8"`
- 예: `"C.UTF-8" "C.UTF-8" → "C.UTF-8"`
- 예: `"" "" → "C.UTF-8"`

### settings_is_secret
- 역할: 설정 키가 비밀 키 목록(토큰 등)에 있으면 참
- 위치: scripts/lib/settings.sh · @pure · sh
- 예: `SLACK_BOT_TOKEN → ""`
- 예: `SCV_LANG → "" [1]`
- 예: `'' → "" [1]`
