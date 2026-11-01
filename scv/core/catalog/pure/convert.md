# 변환 — 한 표기를 다른 표기로 바꾼다 — 경로 · 날짜 · 단위 · 인코딩

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 22개.

### scv_as_group_of
- 역할: 파일 경로에서 묶음 이름을 낸다 — 보관된 계획의 네 문서는 폴더 이름 하나로 합친다
- 위치: scripts/lib/archive-search.sh · @pure
- 예: `scv/archive/20260101-a-x/PLAN.md → "20260101-a-x"`
- 예: `scv/archive/20260101-a-x/TESTS.md → "20260101-a-x"`
- 예: `scv/DECISIONS.md → "DECISIONS"`

### scv_dreams_day
- 역할: YYYYMMDD 를 YYYY-MM-DD 로 바꾼다(모양이 다르면 그대로)
- 위치: scripts/lib/dreams.sh · @pure
- 예: `20261001 → '2026-10-01'`
- 예: `abc → 'abc'`

### scv_dreams_period_ord
- 역할: 날짜 YYYYMMDD 를 기간 단위(dekad · month)의 순번 정수로 바꾼다
- 위치: scripts/lib/dreams.sh · @pure
- 예: `20261015 dekad → '72964'`
- 예: `20261015 month → '24321'`

### scv_dreams_period_range
- 역할: 기간 순번과 단위로 "시작 끝" YYYYMMDD 를 낸다
- 위치: scripts/lib/dreams.sh · @pure
- 예: `72964 dekad → '20261011 20261020'`
- 예: `72963 dekad → '20261001 20261010'`

### scv_dreams_tag
- 역할: «  » 로 적은 짧은 HTML 조각을 꺾쇠 태그로 바꾼다
- 위치: scripts/lib/dreams.sh · @pure
- 예: `"«b»hi«/b»" → '<b>hi</b>'`

### scv_graph_normpath
- 역할: 경로의 "./" 와 "a/../" 를 접고 겹친 슬래시를 하나로 줄인다 (앞의 "/" 는 유지하지 않는다)
- 위치: scripts/lib/graph.sh · @pure
- 예: `"./a/b/../c.md" → "a/c.md"`
- 예: `"a/./b//c" → "a/b/c"`

### scv_hstate_mark
- 역할: 상태를 "규약을 읽었다"(protocol=1)로 바꾸고, 새 지문을 주면 그것으로 갈아 끼운다
- 위치: scripts/lib/help-state.sh · @pure
- 예: `$'s1\x1f0\x1f3\x1fab12\x1f09:30\x1f' cafe0000 → $'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fcafe0000'`

### scv_hstate_reload
- 역할: 상태 · 세션 번호 · 사건(prompt|reset) · N 으로 규약 재읽기 여부를 반영한 새 상태를 낸다
- 위치: scripts/lib/help-state.sh · @pure
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' s1 prompt 0 → $'s1\x1f1\x1f4\x1fab12\x1f09:30\x1fdeadbeef'`
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' s2 prompt 0 → $'s2\x1f0\x1f1\x1f\x1f\x1f'`
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' s1 reset 0 → $'s1\x1f0\x1f3\x1fab12\x1f09:30\x1f'`

### scv_mp_guides_dir
- 역할: 프로필 값이 절대 경로면 그대로, 상대 경로면 코어 루트 아래 경로로 바꾼다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `/root guides → "/root/guides"`
- 예: `/root /abs/g → "/abs/g"`
- 예: `/root "" → ""`

### scv_mp_principle_lang
- 역할: SCV_LANG 값을 원칙 구역 이름(korean · english · japanese)으로 바꾼다
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `ko → "korean"`
- 예: `"" → "english"`
- 예: `FR → "fr"`

### scv_mp_restamp
- 역할: 읽음 기록의 옛 지문을 새 지문으로 바꾼 줄을 낸다(옛 지문이 다르면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `$'old\x1fm' old new → $'new\x1fm'`
- 예: `$'zzz\x1fm' old new → ""`

### scv_mp_turn_restamp
- 역할: 이번 턴 기록의 옛 지문을 새 지문으로 바꾼 줄을 낸다(맞지 않으면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure
- 예: `$'old\x1fm\x1fload\x1fk' old new → $'new\x1fm\x1fload\x1fk'`
- 예: `$'zz\x1fm\x1fload\x1fk' old new → ""`

### scv_mx_civil_to_minutes
- 역할: "YYYY-MM-DD HH:MM" 을 1970-01-01 00:00 기준 분 수로 바꾼다 (형식이 아니면 빈 값)
- 위치: scripts/lib/metrics.sh · @pure
- 예: `"1970-01-02 00:30" → "1470"`
- 예: `"nope" → ""`

### scv_mx_fmt10
- 역할: 10배 한 정수를 소수 한 자리 "d.d" 로 바꾼다 (빈 값이면 "—")
- 위치: scripts/lib/metrics.sh · @pure
- 예: `25 → "2.5"`
- 예: `"" → "—"`

### scv_mx_resolve_conv_path
- 역할: 계획서에 적힌 대화 경로를 SCV_DIR 기준 후보 경로 두 줄(그대로 · archive 아래)로 바꾼다
- 위치: scripts/lib/metrics.sh · @pure
- 예: `"scv/conversations/c1.md" → $'conversations/c1.md\nconversations/archive/c1.md'`

### scv_reg_rewrite_line
- 역할: 시험 줄이면 그 명령을 기록된 종료 코드 '( exit N )' 로 바꾸고 앞 공백 · 꼬리는 남긴다 — 표에 없으면 그대로
- 위치: scripts/lib/regression-memo.sh · @pure
- 예: `"  bash t/a.sh >/dev/null || fail a" $'bash t/a.sh\t1' → "  ( exit 1 ) >/dev/null || fail a"`
- 예: `"bash t/b.sh" $'bash t/a.sh\t0' → "bash t/b.sh"`
- 예: `"bash t/a.sh && bash t/b.sh" $'bash t/a.sh\t0\nbash t/b.sh\t1' → "( exit 0 ) && ( exit 1 )"`

### scv_show_real_lines
- 역할: \x1e 로 이은 글을 줄바꿈으로 나눈 글로 바꾼다
- 위치: scripts/lib/show-real.sh · @pure
- 예: `$'a\036b' → $'a\nb'`
- 예: `"" → ""`

### scv_show_real_local_date
- 역할: 기록 시각(UTC 또는 ±시간대)과 지역 오프셋(분)으로 그 지역의 날짜 YYYYMMDD 를 낸다
- 위치: scripts/lib/show-real.sh · @pure
- 예: `"2026-10-01T20:30:00Z" 540 → '20261002'`
- 예: `"2026-03-01T00:30:00+09:00" 0 → '20260228'`
- 예: `"nope" 0 → ""`

### scv_show_real_merge
- 역할: 분류된 턴 줄들에서 답이 yes 인 턴의 보여 줌 칸만 1 로 바꾼다
- 위치: scripts/lib/show-real.sh · @deterministic
- 예: `$'s1\t2026-10-01T01:00:00Z\t1\t0\t1\t0\t0' $'A\tk\ts1\t2026-10-01T01:00:00Z\tb\tyes' → $'s1\t2026-10-01T01:00:00Z\t1\t1\t1\t0\t0'`

### scv_show_real_offset
- 역할: +HHMM · -HHMM 모양의 오프셋을 분으로 바꾼다(모양이 다르면 0)
- 위치: scripts/lib/show-real.sh · @pure
- 예: `+0900 → '540'`
- 예: `-0530 → '-330'`
- 예: `abc → '0'`

### scv_show_real_range
- 역할: 기간 글 YYYY-MM-DD..YYYY-MM-DD 를 "시작 끝" YYYYMMDD 두 값으로 바꾼다(잘못된 기간은 빈 값)
- 위치: scripts/lib/show-real.sh · @pure
- 예: `"2026-10-01..2026-10-11" → '20261001 20261011'`
- 예: `"2026-10-11..2026-10-01" → ""`

### settings_merge_defaults
- 역할: 사용자 JSON 에 기본값 JSON 을 깔아 병합한다 — 사용자 값이 이긴다
- 위치: scripts/lib/settings.sh · @deterministic
- 예: `'{"a":1}' '{"a":0,"b":2}' → $'{\n  "a": 1,\n  "b": 2\n}'`
