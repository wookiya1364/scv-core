# 지문 — 내용에서 짧은 식별값을 만든다 — 해시 · 키 · 이름

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 6개.

### decisions_slug
- 역할: 제목에서 부를 이름을 만든다 — 소문자 · 숫자 · 한글만 남기고 나머지는 -, 최대 48자
- 위치: scripts/decisions-append.sh · @pure
- 예: `'Hello, World!  Fix #12' → "hello-world-fix-12"`
- 예: `'  --a--  ' → "a"`

### scv_digest_fold
- 역할: 표준입력 줄들을 정렬한 뒤 sha256 지문 하나로 접는다 — 줄 순서와 무관
- 위치: scripts/lib/template-digest.sh · @deterministic
- 예: `<<< $'b\na' → "911169ddaaf146aff539f58c26c489af3b892dff0fe283c1c264c65ae5aa59a2"`
- 예: `<<< $'a\nb' → "911169ddaaf146aff539f58c26c489af3b892dff0fe283c1c264c65ae5aa59a2"`
- 예: `<<< $'a' → "87428fc522803d31065e7bce3cf03fe475096631e5e07bbd7a0fde60c4cf25c7"`

### scv_graph_community
- 역할: 노드 종류 · id · epic 으로 군집 라벨을 정한다 (파일은 상위 두 폴더, 계획은 epic 아니면 슬러그 연월, 결정은 "decisions")
- 위치: scripts/lib/graph.sh · @pure
- 예: `plan 20261101-x-y → "2026-11"`
- 예: `plan 20261101-x-y epic1 → "epic1"`
- 예: `file core/scripts/lib/a.sh → "core/scripts"`
- 예: `decision x → "decisions"`

### scv_rc_demand_keys
- 역할: 표준입력 "파일 줄번호 본문" 줄에서 앞 8단어 키를 만들어 "키 파일" 로 낸다(6단어 미만은 버림)
- 위치: scripts/lib/rule-constitution.sh · @deterministic
- 예: `<<< $'a.md\t1\tYou MUST always run the unit tests first, then commit.' → $'you must always run the unit tests first\ta.md'`
- 예: `<<< $'a.md\t1\tToo short line' → ""`

### scv_show_real_hash
- 역할: 글의 SHA-256 16진 지문을 낸다
- 위치: scripts/lib/show-real.sh · @deterministic
- 예: `"abc" → 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'`

### scv_show_real_keys
- 역할: 발췌 줄마다 (세션 · 시각 · 발췌)의 해시 열쇠를 앞에 붙인다
- 위치: scripts/lib/show-real.sh · @deterministic
- 예: `$'s1\t2026-10-01T01:00:00Z\tb\tx' → $'8a27eeea88600e4df47837f14e10d4670017a6d8fb91bb51612b8782242d1430\ts1\t2026-10-01T01:00:00Z\tb\tx'`
